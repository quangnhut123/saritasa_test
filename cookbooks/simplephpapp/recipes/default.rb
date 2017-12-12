#
# Cookbook Name:: simplephpapp
# Recipe:: default
#
# Helper to identify if php7 is already installed
module Php7Helper
  include Chef::Mixin::ShellOut

  def php7_installed?
    cmd = shell_out("php -v | grep -q PHP")
    if (cmd.exitstatus == 0)
      return true
    else
      return false
    end
  end
end

Chef::Resource.send(:include, Php7Helper)

#Upgrade system
execute "update-upgrade" do
  command "yum update -y && yum upgrade -y"
  action :run
  not_if { php7_installed? }
end

#Install epel repo
execute "install-epel-repo" do
  command "rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm"
  action :run
  not_if { php7_installed? }
end

#Install webtatic repo
execute "install-webtatic-repo" do
  command "rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm"
  action :run
  not_if { php7_installed? }
end

# Install needed packages
package [
    "net-tools",
    "git",
    "nano",
    "nodejs",
    "nginx",
    "php71w",
    "php71w-common",
    "php71w-fpm",
    "php71w-cli",
    "php71w-mbstring",
    "php71w-xml",
    "php71w-pdo"
  ]  do
  action :install
  not_if { php7_installed? }
end

#Install composer
execute "install-composer-package" do
  command "curl -sS https://getcomposer.org/installer | php && sudo mv composer.phar /usr/local/bin/composer"
  action :run
  not_if { File.exists?("/usr/local/bin/composer") }
end

#Make web root
directory '/var/www' do
  owner 'apache'
  group 'apache'
  mode '0755'
  action :create
end

#Copy application source from host to guest
cookbook_file "Copy-source-code" do  
  group "apache"
  owner "apache"
  mode "0644"
  path "/var/www/simplephpapp.tar.gz"
  source "simplephpapp.tar.gz"
  not_if { File.exists?("/var/www/simplephpapp.tar.gz") }  
end

#Extract tarball
execute 'extract-tarball' do
  command 'tar xzvf simplephpapp.tar.gz'
  cwd '/var/www'
end

#Install composer dependencies
execute "install-composer-dependencies" do
  command "/usr/local/bin/composer install -vvv"
  cwd '/var/www/simplephpapp'
  action :run
end

#Configuration simplephpapp
execute "configure-app" do
  command "cp .env.example .env && php artisan key:generate && npm install --verbose"
  cwd '/var/www/simplephpapp'
  action :run
end

#Start simplephpapp
execute "start-app" do
  command "npm run production"
  cwd '/var/www/simplephpapp'
  action :run
end

# create nginx server block file
template "nginx-config" do
  path "/etc/nginx/nginx.conf"
  source "default.conf.erb"
end

# Start php fpm service
service "start-php-fpm" do
  service_name "php-fpm"
  supports :restart => true
  action [ :enable, :restart ] 
end

# Start nginx service
service "start-nginx" do
  service_name "nginx"
  supports :restart => true
  action [ :enable, :restart ] 
end

#Correct permission for webroot folder
execute 'correct-permission' do
  command "sudo chown -R #{node['nginx']['user']}:#{node['nginx']['user']} /var/www"
  action :run
end

#Allow writing with selinux
execute "selinux_allow" do
  command "chcon -R -t httpd_sys_rw_content_t storage"
  cwd '/var/www/simplephpapp'
  action :run
end





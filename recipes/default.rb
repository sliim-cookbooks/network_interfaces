#
# Cookbook Name:: network_interfaces
# Recipe:: default
#
# Author:: Stanislav Bogatyrev <realloc@realloc.spb.ru>
# Author:: Guilhem Lettron <guilhem.lettron@youscribe.com>
#
# Copyright 2012, Clodo.ru
# Copyright 2012, Societe Publica.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require "pathname"

# Reset ifaces order on each run
node.default["network_interfaces"]["order"]=[]

ruby_block "Merge interfaces" do
  block do
    File.open("/etc/network/interfaces", "w") do |ifaces|
      ( ["/etc/network/interfaces.tpl"] + node["network_interfaces"]["order"].map{|ifile| "/etc/network/interfaces.d/#{ifile}"} ).uniq.compact.each do |ifile|
        File.open(ifile) do |f|
          f.each_line { |line| ifaces.write(line) }
        end
      end
    end
  end
  only_if { debian_before_or_squeeze? or ubuntu_before_or_natty? }
  action :nothing
end

template "/etc/network/interfaces" do
  source "interfaces.merged.erb"
  owner "root"
  group "root"
  mode "0644"
  variables(
    :files => ["/etc/network/interfaces.tpl"] + Array(Pathname.new("/etc/network/interfaces.d").children.select { |c| c.file? }.collect { |p| p.to_s })
  )
  only_if { debian_before_or_squeeze? or ubuntu_before_or_natty? }
  action :nothing
end

if (debian_before_or_squeeze? || ubuntu_before_or_natty?)
  cookbook_file "/etc/network/interfaces.tpl" do
    source "interfaces"
    mode 0644
    owner "root"
    group "root"
  end
elsif node["network_interfaces"]["replace_orig"]
  cookbook_file "/etc/network/interfaces" do
    source "interfaces"
    mode 0644
    owner "root"
    group "root"
  end
end

ruby_block "Fix interfaces include" do
  block do
    unless debian_before_or_squeeze? || ubuntu_before_or_natty?
      file = Chef::Util::FileEdit.new("/etc/network/interfaces")
      file.insert_line_if_no_match("^source /etc/network/interfaces.d/*", 'source /etc/network/interfaces.d/*')
      file.write_file
    end
  end
end

directory "/etc/network/interfaces.d" do
  owner "root"
  group "root"
  mode "0644"
  action :create
end

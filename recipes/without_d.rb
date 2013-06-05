# Reset ifaces order on each run
#node.default["network_interfaces"]["order"]=[]

#ruby_block "Merge interfaces" do
#  block do
#    File.open("/etc/network/interfaces", "w") do |ifaces|
#      ( ["/etc/network/interfaces.tpl"] + node["network_interfaces"]["order"].map{|ifile| "/etc/network/interfaces.d/#{ifile}"} ).uniq.compact.each do |ifile|
#        File.open(ifile) do |f|
#          f.each_line { |line| ifaces.write(line) }
#        end
#      end
#    end
#  end
#  only_if { debian_before_or_squeeze? or ubuntu_before_or_natty? }
#  action :nothing
#end

require 'pathname'

cookbook_file "/etc/network/interfaces.tpl" do
  source "interfaces"
  mode 0644
  owner "root"
  group "root"
end

template "interfaces merged" do
  path "/etc/network/interfaces"
  source "interfaces.merged.erb"
  owner "root"
  group "root"
  mode "0644"
  variables(
    :files => ["/etc/network/interfaces.tpl"] + Array(Pathname.new("/etc/network/interfaces.d").children.select { |c| c.file? }.collect { |p| p.to_s })
  )
end

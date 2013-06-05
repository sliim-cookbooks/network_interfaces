cookbook_file "/etc/network/interfaces" do
  source "interfaces"
  mode 0644
  owner "root"
  group "root"
  only_if node["network_interfaces"]["replace_orig"]
end

ruby_block "Fix interfaces include" do
  block do
    file = Chef::Util::FileEdit.new("/etc/network/interfaces")
    file.insert_line_if_no_match("^source /etc/network/interfaces.d/*", 'source /etc/network/interfaces.d/*')
    file.write_file
  end
end

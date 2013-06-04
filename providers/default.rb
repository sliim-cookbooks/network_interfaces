action :save do
  
  node.default["network_interfaces"]["order"] << new_resource.device

  if new_resource.bridge and new_resource.bridge.class != Array
    new_resource.bridge = [ "none" ]
  end

  if new_resource.vlan_dev || new_resource.device =~ /(eth|bond|wlan)[0-9]+\.[0-9]+/
    package "vlan"
    modules "8021q"

  end

  if new_resource.bond and new_resource.bond.class != Array
    new_resource.bond = [ "none" ]
  end

  if new_resource.bond
    package "ifenslave-2.6"

    modules "bonding"
  end

  if new_resource.bootproto == "dhcp"
    type = "dhcp"
  elsif ! new_resource.target
    type = "manual"
  else
    type = "static"
  end

  if get_value(:metric,new_resource.device, resource=new_resource, node)
    package "ifmetric"
  end

  if new_resource.bridge
    package "bridge-utils"
  end

  execute "if_up #{new_resource.name}" do
    command "ifdown #{new_resource.device} -i /etc/network/interfaces.d/#{new_resource.device} ; ifup #{new_resource.device} -i /etc/network/interfaces.d/#{new_resource.device}"
    only_if "ifdown -n #{new_resource.device} -i /etc/network/interfaces.d/#{new_resource.device} ; ifup -n #{new_resource.device} -i /etc/network/interfaces.d/#{new_resource.device}"
    action :nothing
  end

  template "/etc/network/interfaces.d/#{new_resource.device}" do
    cookbook "network_interfaces"
    source "interfaces.erb"
    owner "root"
    group "root"
    mode "0644"
    variables(
      :auto => get_value(:onboot,new_resource.device, resource=new_resource, node),
      :type => type,
      :device => new_resource.device,
      :address => get_value(:target,new_resource.device, resource=new_resource, node),
      :network => get_value(:network,new_resource.device, resource=new_resource, node),
      :netmask => get_value(:mask,new_resource.device, resource=new_resource, node),
      :gateway => get_value(:gateway,new_resource.device, resource=new_resource, node),
      :broadcast => get_value(:broadcast,new_resource.device, resource=new_resource, node),
      :bridge_ports => get_value(:bridge,new_resource.device, resource=new_resource, node),
      :bridge_stp => get_value(:bridge_stp,new_resource.device, resource=new_resource, node),
      :vlan_dev => get_value(:vlan_dev,new_resource.device, resource=new_resource, node),
      :bond_slaves => get_value(:bond,new_resource.device, resource=new_resource, node),
      :bond_mode => get_value(:bond_mode,new_resource.device, resource=new_resource, node),
      :metric => get_value(:metric,new_resource.device, resource=new_resource, node),
      :mtu => get_value(:mtu,new_resource.device, resource=new_resource, node),
      :pre_up => get_value(:pre_up,new_resource.device, resource=new_resource, node),
      :up => get_value(:up,new_resource.device, resource=new_resource, node),
      :post_up => get_value(:post_up,new_resource.device, resource=new_resource, node),
      :pre_down => get_value(:pre_down,new_resource.device, resource=new_resource, node),
      :down => get_value(:down,new_resource.device, resource=new_resource, node),
      :post_down => get_value(:post_down,new_resource.device, resource=new_resource, node),
      :custom => get_value(:custom,new_resource.device, resource=new_resource, node)
    )
    notifies :run, "execute[if_up #{new_resource.name}]", :immediately
    notifies :create, "ruby_block[Merge interfaces]", :delayed
  end
end

action :remove do
  execute "if_down #{new_resource.name}" do
    command "ifdown #{get_value(:device,new_resource.device, resource=new_resource, node)} -i /etc/network/interfaces.d/#{get_value(:device,new_resource.device, resource=new_resource, node)}"
    only_if "ifdown -n #{get_value(:device,new_resource.device, resource=new_resource, node)} -i /etc/network/interfaces.d/#{get_value(:device,new_resource.device, resource=new_resource, node)}"
  end

  file "/etc/network/interfaces.d/#{new_resource.device}" do
    action :delete
    notifies :run, "execute[if_down #{new_resource.name}]", :immediately
    notifies :create, "ruby_block[Merge interfaces]", :delayed
  end
end

# -*- mode: ruby -*-
# vi: set ft=ruby :
# // To list interfaces on CLI typically:
# //	macOS: networksetup -listallhardwareports ;
# //	Linux: lshw -class network ;
#sNET='en0: Wi-Fi (Wireless)'  # // network adaptor to use for bridged mode
sNET='en7: USB 10/100/1000 LAN'  # // network adaptor to use for bridged mode
sVUSER='vagrant'  # // vagrant user
sHOME="/home/#{sVUSER}"  # // home path for vagrant user
sPTH='cc.os.user-input'  # // path where scripts are expected
sCA_CERT='cacert.crt'  # // Root CA certificate.

iCLUSTERA_N = 1  # // Vault A INSTANCES UP TO 9 <= iN > 0
iCLUSTERA_C = 0  # // Consul B INSTANCES UP TO 9 <= iN > 0
bCLUSTERA_CONSUL = false  # // Consul A use Consul as store for vault?
CLUSTERA_VAULT_NAME = 'dc1'  # // Vault A Cluster Name
CLUSTERA_HOSTNAME_PREFIX = 'dc1-'  # // Vault A Cluster Name
sCLUSTERA_IP_CLASS_D='192.168.178'  # // Consul A NETWORK CIDR forconfigs.
iCLUSTERA_IP_CONSUL_CLASS_D=110  # // Consul A IP starting D class (increment or de)
iCLUSTERA_IP_VAULT_CLASS_D=177  # // Vault A Leader IP starting D class (increment or de)
sCLUSTERA_IP_CA_NODE="#{sCLUSTERA_IP_CLASS_D}.#{iCLUSTERA_IP_VAULT_CLASS_D-1}"  # // Cluster A - static IP of CA
sCLUSTERA_sIP_VAULT_LEADER="#{sCLUSTERA_IP_CA_NODE}"  # // Vault A static IP of CA

sCLUSTERA_sIP="#{sCLUSTERA_IP_CLASS_D}.199"  # // HAProxy Load-Balancer IP

sCLUSTERA_IPS=''  # // Consul A - IPs constructed based on IP D class + instance number
aCLUSTERA_FILES =  # // Cluster A files to copy to instances
[
	"vault_files/."  # "vault_files/vault_seal.hcl", "vault_files/vault_license.txt"  ## // for individual files
];
VV1=''  # 'VAULT_VERSION='+'1.5.0+ent.hsm'  # VV1='' to Install Latest OSS
VR1=''  # "VAULT_RAFT_JOIN=https://#{sCLUSTERA_sIP_VAULT_LEADER}:8200"  # raft join script determines applicability

sERROR_MSG_CONSUL="CONSUL Node count can NOT be zero (0). Set to: 3, 5, 7 , 11, etc."

Vagrant.configure("2") do |config|
	config.vm.box = "debian/buster64"
	config.vm.box_check_update = false  # // disabled to reduce verbosity - better enabled
	#config.vm.box_version = "10.4.0"  # // Debian tested version.
	# // OS may be "ubuntu/bionic64" or "ubuntu/focal64" as well.

	config.vm.provider "virtualbox" do |v|
		v.memory = 1024  # // RAM / Memory
		v.cpus = 1  # // CPU Cores / Threads
		v.check_guest_additions = false  # // disable virtualbox guest additions (no default warning message)
	end

	# // ESSENTIALS PACKAGES INSTALL & SETUP
	config.vm.provision "shell" do |s|
		 s.path = "#{sPTH}/1.install_commons.sh"
	end

	config.vm.define vm_name2="haproxy" do |haproxy_node|
		haproxy_node.vm.hostname = vm_name2
		haproxy_node.vm.network "public_network", bridge: "#{sNET}", ip: "#{sCLUSTERA_sIP}"
		# haproxy_node.vm.network "forwarded_port", guest: 80, host: "48080", id: "#{vm_name2}"

		# // ORDERED: setup certs then call HAProxy setup.
		haproxy_node.vm.provision "file", source: "#{sPTH}/3.install_tls_ca_certs.sh", destination: "#{sHOME}/install_tls_ca_certs.sh"
		haproxy_node.vm.provision "file", source: "#{sPTH}/4.install_haproxy.sh", destination: "#{sHOME}/install_haproxy.sh"
		haproxy_node.vm.provision "shell", inline: <<-SCRIPT
#{sHOME}/install_tls_ca_certs.sh #{iCLUSTERA_N} ;
#{sHOME}/install_haproxy.sh ;
# // allow for SSHD on all interfaces
sed -i "s/#ListenAddress/ListenAddress/g" /etc/ssh/sshd_config ;

SCRIPT
# "bash -c '#{sHOME}/install_tls_ca_certs.sh #{iCLUSTERA_N} && #{sHOME}/install_haproxy.sh'"
#		haproxy_node.vm.provision "shell", inline: 'sed -i "s/#ListenAddress/ListenAddress/g" /etc/ssh/sshd_config'
      end


	# // ------ CLUSTER A ------ CLUSTER A ------
	# // Consul Server Nodes
	if bCLUSTERA_CONSUL then
		if iCLUSTERA_C == 0 then STDERR.puts "\e[31m#{sERROR_MSG_CONSUL}\e[0m" ; exit(3) ; end ;
		(1..iCLUSTERA_C-1).each do |iY|  # // CONSUL Server Nodes IP's for join (concatenation)
			sCLUSTERA_IPS+="\"#{sCLUSTERA_IP_CLASS_D}.#{iCLUSTERA_IP_CONSUL_CLASS_D+iY}\"" + (iY < iCLUSTERA_C ? ", " : "")
		end
		# // CONSUL AGENT SCRIPTS to setup
		config.vm.provision "file", source: "#{sPTH}/2.install_consul.sh", destination: "#{sHOME}/install_consul.sh"
		# // CONSUL Server Nodes
		(1..iCLUSTERA_C).each do |iY|
			config.vm.define vm_name="#{CLUSTERA_HOSTNAME_PREFIX}consul#{iY}" do |consul_node|
				consul_node.vm.hostname = vm_name
				consul_node.vm.network "public_network", bridge: "#{sNET}", ip: "#{sCLUSTERA_IP_CLASS_D}.#{iCLUSTERA_IP_CONSUL_CLASS_D+iY}"
				# consul_node.vm.network "forwarded_port", guest: 80, host: "5818#{iY}", id: "#{vm_name}"
				$script = <<-SCRIPT
sed -i 's/\"__IPS-SET__\"/#{sCLUSTERA_IPS}/g' #{sHOME}/install_consul.sh
/bin/bash -c #{sHOME}/install_consul.sh
SCRIPT
				consul_node.vm.provision "shell", inline: $script
			end
		end
	end
	# // VAULT Server Nodes as Consul Clients as well.
	(1..iCLUSTERA_N).each do |iX|
		config.vm.define vm_name="#{CLUSTERA_HOSTNAME_PREFIX}vault#{iX}" do |vault_node|
			vault_node.vm.hostname = vm_name
			vault_node.vm.network "public_network", bridge: "#{sNET}", ip: "#{sCLUSTERA_IP_CLASS_D}.#{iCLUSTERA_IP_VAULT_CLASS_D-iX}"
			# vault_node.vm.network "forwarded_port", guest: 80, host: "5828#{iX}", id: "#{vm_name}"

			if bCLUSTERA_CONSUL then
				$script = <<-SCRIPT
sed -i 's/\"__IPS-SET__\"/#{sCLUSTERA_IPS}/g' #{sHOME}/install_consul.sh
/bin/bash -c 'SETUP=client #{sHOME}/install_consul.sh'
SCRIPT
				vault_node.vm.provision "shell", inline: $script
			end

			# // ORDERED: Copy certs & ssh private keys before setup from vault1 / CA source generating.
			vault_node.vm.provision "file", source: ".vagrant/machines/haproxy/virtualbox/private_key", destination: "#{sHOME}/.ssh/id_rsa2"
			$script = <<-SCRIPT
ssh-keyscan #{sCLUSTERA_sIP} 2>/dev/null >> #{sHOME}/.ssh/known_hosts ; chown #{sVUSER}:#{sVUSER} -R #{sHOME}/.ssh ;
su -l #{sVUSER} -c \"rsync -qva --rsh='ssh -i #{sHOME}/.ssh/id_rsa2' #{sVUSER}@#{sCLUSTERA_sIP}:~/vault#{iX}* :~/#{sCA_CERT} #{sHOME}/.\"
SCRIPT
			vault_node.vm.provision "shell", inline: $script

			# // ORDERED: setup certs.
			vault_node.vm.provision "file", source: "#{sPTH}/3.install_tls_ca_certs.sh", destination: "#{sHOME}/install_tls_ca_certs.sh"
			vault_node.vm.provision "shell", inline: "/bin/bash -c '#{sHOME}/install_tls_ca_certs.sh'"

			# // where additional Vault related files exist copy them across (eg License & seal configuration)
			for sFILE in aCLUSTERA_FILES
				if(File.file?("#{sFILE}") || File.directory?("#{sFILE}"))
					vault_node.vm.provision "file", source: "#{sFILE}", destination: "#{sHOME}"
				end
			end

			# // ORDERED: copy VAULT TOKEN to .bashrc for convenience from main node after setup.
			if iX > 1 then
				vault_node.vm.provision "shell", inline: "su -l #{sVUSER} -c 'ssh-keyscan #{sCLUSTERA_sIP_VAULT_LEADER} 2>/dev/null >> #{sHOME}/.ssh/known_hosts ; VT=$(ssh -i #{sHOME}/.ssh/id_rsa2 #{sVUSER}@#{sCLUSTERA_sIP_VAULT_LEADER} \"[[ -f /home/vagrant/vault_token.txt ]] && cat /home/vagrant/vault_token.txt || printf \'\'\"); if ! [[ ${VT} == \"\" ]] && ! grep VAULT_TOKEN ~/.bashrc ; then printf \"export VAULT_TOKEN=${VT}\n\" >> ~/.bashrc ; fi ;'"
			end

			# // ORDERED: setup vault
			vault_node.vm.provision "file", source: "#{sPTH}/5.install_vault.sh", destination: "#{sHOME}/install_vault.sh"
			if iX == 1 then
				# // Cluster A ONLY - ENABLE DR & Related Settings will occure as part of vault setup from vault_post_setup.sh script.
				# // DR specific script invoked by Vault Setup script.
				vault_node.vm.provision "file", source: "#{sPTH}/6.post_setup_vault.sh", destination: "#{sHOME}/post_setup_vault.sh"
				vault_node.vm.provision "shell", inline: "/bin/bash -c '#{VV1} TLS_ENABLE='false' VAULT_CLUSTER_NAME='#{CLUSTERA_VAULT_NAME}' USER='#{sVUSER}' #{sHOME}/install_vault.sh'"
			else
				vault_node.vm.provision "shell", inline: "/bin/bash -c '#{VV1} #{VR1} TLS_ENABLE='false VAULT_CLUSTER_NAME='#{CLUSTERA_VAULT_NAME}' USER='#{sVUSER}' #{sHOME}/install_vault.sh'"
			end

			# // DESTROY ACTION - need to perform raft peer remove if its not the last node:
			vault_node.trigger.before :destroy do |trigger|
				if iCLUSTERA_C == 0 && iCLUSTERA_N > 1 then
					trigger.run_remote = {inline: "printf 'RAFT CHECKING: if Removal from Qourum peers-list is required.\n' && bash -c 'set +eu ; export VAULT_TOKEN=\"$(grep -F VAULT_TOKEN #{sHOME}/.bashrc | cut -d= -f2)\" ; if (($(vault operator raft list-peers -format=json 2>/dev/null | jq -r \".data.config.servers|length\") == 1)) ; then echo \"RAFT: Last Node - NOT REMOVING.\" && exit 0 ; fi ; VS=$(vault status | grep -iE \"Raft\") ; if [[ \${VS} == *\"Raft\"* ]] ; then vault operator raft remove-peer \$(hostname) 2>&1>/dev/null && printf \"Peer removed successfully!\n\" ; fi ;'"}
				end
			end
		end
	end
end


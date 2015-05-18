class Homestead
  def Homestead.configure(config, settings)
    # Configure The Box
    config.vm.box = "laravel/homestead"

    # Configure Local Variable To Access Scripts From Remote Location
    scriptDir = File.dirname(__FILE__)

    # Configure all of the boxes
    settings["boxes"].each do |box|
      config.vm.define box["name"] do |vmbox|

        vmbox.vm.network :private_network, ip: box["ip"]

        # Use the IP to create the box index (used for port offsets)
        ip_segments = box["ip"].split(".").map(&:to_i)
        box_index = (ip_segments[3] - 20)

        # Standardize Ports Naming Schema
        if (settings.has_key?("ports"))
          settings["ports"].each do |port|
            port["guest"] ||= port["to"]
            port["host"] ||= port["send"]
            port["protocol"] ||= "tcp"
          end
        else
          settings["ports"] = []
        end

        # Default Port Forwarding
        if (box["name"] == "db")
          default_ports = {
            3306 => (33060 + box_index)
          }
        else 
          default_ports = {
            80   => (8000 + box_index),
            443  => (44300 + box_index)
          }
        end

        # Use Default Port Forwarding Unless Overridden
        default_ports.each do |guest, host|
          unless settings["ports"].any? { |mapping| mapping["guest"] == guest }
            vmbox.vm.network "forwarded_port", guest: guest, host: host
          end
        end

        # Add Custom Ports From Configuration
        if settings.has_key?("ports")
          settings["ports"].each do |port|
            vmbox.vm.network "forwarded_port", guest: port["guest"], host: (port["host"] + box_index), protocol: port["protocol"]
          end
        end

        # Configure The Public Key For SSH Access
        if settings.include? 'authorize'
          vmbox.vm.provision "shell" do |s|
            s.inline = "echo $1 | grep -xq \"$1\" /home/vagrant/.ssh/authorized_keys || echo $1 | tee -a /home/vagrant/.ssh/authorized_keys"
            s.args = [File.read(File.expand_path(settings["authorize"]))]
          end
        end

        # Copy The SSH Private Keys To The Box
        if settings.include? 'keys'
          settings["keys"].each do |key|
            vmbox.vm.provision "shell" do |s|
              s.privileged = false
              s.inline = "echo \"$1\" > /home/vagrant/.ssh/$2 && chmod 600 /home/vagrant/.ssh/$2"
              s.args = [File.read(File.expand_path(key)), key.split('/').last]
            end
          end
        end

        # Register All Of The Configured Shared Folders
        if settings.include? 'folders'
          settings["folders"].each do |folder|
            mount_opts = folder["type"] == "nfs" ? ['actimeo=1'] : []
            vmbox.vm.synced_folder folder["map"], folder["to"], type: folder["type"] ||= nil, mount_options: mount_opts
          end
        end

        # Configure A Few VirtualBox Settings
        vmbox.vm.provider "virtualbox" do |vb|
          vb.name = 'homestead_' + box["name"]
          vb.customize ["modifyvm", :id, "--memory", settings["memory"] ||= "2048"]
          vb.customize ["modifyvm", :id, "--cpus", settings["cpus"] ||= "1"]
          vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
          vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
          vb.customize ["modifyvm", :id, "--ostype", "Ubuntu_64"]
        end

        if (box["name"] == "db")
          # Configure All Of The Configured Databases
          settings["databases"].each do |db|
            vmbox.vm.provision "shell" do |s|
              s.path = scriptDir + "/create-mysql.sh"
              s.args = [db]
            end
          end
        else

          # Initialize the server
          vmbox.vm.provision "shell" do |s|
            s.path = scriptDir + "/serve.sh"
            s.args = [box["map"], box["to"]]
          end

          # Configure All Of The Server Environment Variables
          if settings.has_key?("variables")
            settings["variables"].each do |var|
              vmbox.vm.provision "shell" do |s|
                s.inline = "echo \"\nenv[$1] = '$2'\" >> /etc/php5/fpm/php-fpm.conf"
                s.args = [var["key"], var["value"]]
              end

              vmbox.vm.provision "shell" do |s|
                  s.inline = "echo \"\n#Set Homestead environment variable\nexport $1=$2\" >> /home/vagrant/.profile"
                  s.args = [var["key"], var["value"]]
              end
            end

            vmbox.vm.provision "shell" do |s|
              s.inline = "service php5-fpm restart"
            end
          end

          # Update Composer On Every Provision
          vmbox.vm.provision "shell" do |s|
            s.inline = "/usr/local/bin/composer self-update"
          end

          # Configure Blackfire.io
          if settings.has_key?("blackfire")
            vmbox.vm.provision "shell" do |s|
              s.path = scriptDir + "/blackfire.sh"
              s.args = [
                settings["blackfire"][0]["id"],
                settings["blackfire"][0]["token"],
                settings["blackfire"][0]["client-id"],
                settings["blackfire"][0]["client-token"]
              ]
            end
          end

        end #else (app box)

      end
    end

  end
end

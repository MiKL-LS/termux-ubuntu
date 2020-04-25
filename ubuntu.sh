#!/data/data/com.termux/usr/bin/bash 
dist="ubuntu" distro="Ubuntu" suite="20.04" # default suite
folder="${dist}-fs" tarball="${dist}.tar.gz"
script="start-${dist}.sh"
current="$(pwd)" # current directory
nameserver1="1.1.1.1" nameserver2="1.0.0.1" # nameservers to make ubuntu work
function install {
	function set_suite() {
		case $suite in
			18.04|19.10|20.04)
				echo "using base image '$suite'... "; type="base";;
			16.04|14.04|12.04)
				echo "Using core image of `$suite`..."; type="core";;
			*)
				echo "Unsupported version '$suite'. Aborting"; exit ;;
		esac
	}
	function check_deps {
		echo -n "Checking dependencies... "
		for dep in proot wget
			do
				function fetch_deps {
					echo -e "\nInstalling ${dep}..."
					pkg install -y ${dep} || { echo "An error occured while trying to download dependencies"; exit; }
					deps=1
				}
				command -v $dep 2&>/dev/null || fetch_deps
			done
		[[ $deps -ne 1 ]] && echo "OK" || { echo -en "\nDependencies installed!\n"; }
	}
	function get_arch {
		arch="$(dpkg --print-architecture)"
		case $arch in
			aarch64) arch="arm64" ;;
			arm) arch="armhf" ;;
			i*86) arch="i386" ;;
			amd64|x64) arch="amd64" ;;
			*) echo "Unsupported architecture ${arch}"; exit ;;
		esac
		echo "Architecture is $arch"
	}
	set_suite "$@"			
	check_deps
	if [ -d $folder ]; then
		first=1
		echo "Skipping download of $tarball"
	fi
	if [ first != 1 ]; then
		if [ ! -f $tarball ]; then
			get_arch
			wget "http://cdimage.ubuntu.com/ubuntu-base/releases/${suite}/release/ubuntu-base-${suite}-${type}-${arch}.tar.gz" -O $tarball
		fi
		mkdir "$folder"
		cd "$folder"
		echo "Decompressing ${distro} tarball..."
		proot --link2symlink tar -xf ${current}/${tarball} || :
		echo "Fixing nameserver..."
		echo -e "namerserver ${nameserver1}\nnameserver ${nameserver2}" > etc/resolv.conf
		cd ${current}
	fi
	mkdir binds
	echo "Writing launch script..."
	cat > ${script} <<- EOF
		#!/data/data/com.termux/files/usr/bin/bash
		cd \$(dirname \$0)
		## unset LD_PRELOAD in case termux-exec is installed
		unset LD_PRELOAD
		command="proot"
		command+=" --link2symlink"
		command+=" -0"
		command+=" -r $folder"
		if [ -n "\$(ls -A binds)" ]; then
			for f in binds/* ;do
				. \$f
			done
		fi
		command+=" -b /dev"
		command+=" -b /proc"
		## uncomment the following line to have access to the home directory of termux
		#command+=" -b /data/data/com.termux/files/home:/root"
		## uncomment the following line to mount /sdcard directly to / 
		#command+=" -b /sdcard"
		command+=" -w /root"
		command+=" /usr/bin/env -i"
			command+=" HOME=/root"
			command+=" PATH=/usr/local/sbin:/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin"
			command+=" TERM=\$TERM"
			command+=" LANG=C.UTF-8"
			command+=" /bin/bash --login"
		com="\$@"
		if [ -z "\$1" ];then
			exec \$command
		else
			\$command -c "\$com"
		fi	
EOF
	echo "Making $script executable..."
	chmod +x $script
	echo "You can now start ${distro} with the ./${script} script"
}
function uninstall() {
    function delete_files() {
        rm -r $script $folder  || echo "An error occured while trying to remove your files" && exit
        echo "done"
    }
    echo -n "Uninstall ${distro}? [Y/n]: "
    read -r opt
    case $opt in
        y|Y) delete_files ;;
        *) echo "Aborted" ;;
    esac
    exit
}
while getopts "v:u" var
	do
		case $var in
			v) suite="$OPTARG" ;;
			u) uninstall; u=1 ;;
			*) echo "Invalid option. Aborting"; u=1;
		esac
	done
[[ $u -ne 1 ]] && install "$@" || exit

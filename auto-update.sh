#!/usr/bin/env bash

echo -e "$(date)."
echo -e " "
echo -e "\e[33m ************************* \e[0m"
echo -e "\e[33m **** Update Starting **** \e[0m"
echo -e "\e[33m ************************* \e[0m"
echo -e " "

echo -e " "
echo -e "\e[33m >>> Check system <<<\e[0m"
echo -e " "

POPPY_ROOT="$HOME/dev"
myDoc_path="$HOME/Jupyter_root/My Documents"
configFile="$HOME/.poppy_config.yaml"

parse_yaml()
{
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
   }'
}
eval $(parse_yaml "$configFile" "old_")
creature=$old_robot_creature
hostname=$old_robot_name

if [[ ! -z "$old_info_version" ]]; then
    echo -e "Puppet-master v $old_info_version doesn't support Update Function!"
    echo -e "In order to update your $creature, flash a new SD card from:"
    echo -e "https://github.com/poppy-project/$creature/releases/latest"
    echo -e "> Docs about how to flash an image file:"
    echo -e "https://docs.poppy-project.org/en/installation/burn-an-image-file.html"
    echo -e ""
    echo -e "\e[33m EXIT Update \e[0m"
    echo -e ""
    exit
fi

v_puppetMaster=$old_version_puppetMaster
v_creature=$old_version_creature
v_pypot=$old_version_pypot
v_snap=$old_version_snap
v_viewer=$old_version_viewer
v_docs=$old_version_docs
v_monitor=$old_version_monitor

echo -e "version puppetMaster = $v_puppetMaster"
echo -e "version $creature = $v_creature"
echo -e "version pypot = $v_pypot"
echo -e "version Snap block = $v_snap"
echo -e "version poppy-viewer = $v_viewer"
echo -e "version poppy-docs = $v_docs"
echo -e "version poppy-monitor = $v_monitor"

echo -e " "
echo -e "\e[33m >>> Target <<<\e[0m"
echo -e " "

branch="master"
b_pypot="$branch"
b_creature="$branch"
b_viewer="_$branch"
b_docs="$branch"
b_monitor="master"

wget "https://raw.githubusercontent.com/poppy-project/puppet-master/$branch/default_config.yaml" -O new_config.yaml
eval $(parse_yaml "new_config.yaml" "new_")
mv -f new_config.yaml "$POPPY_ROOT/puppet-master/default_config.yaml"

n_puppetMaster=$new_version_puppetMaster
n_pypot=$new_version_pypot
n_creature=$new_version_creature
n_viewer=$new_version_viewer
n_docs=$new_version_docs
n_monitor=$new_version_monitor
n_snap=$new_version_snap

echo -e "puppet-Master: branch = $branch, version = $n_puppetMaster "
echo -e "pypot: branch = $b_pypot, version = $n_pypot "
echo -e "$creature: branch = $b_creature, version = $n_creature "
echo -e "viewer: branch = $b_viewer, version = $n_viewer "
echo -e "docs: branch = $b_docs, version = $n_docs "
echo -e "monitor: branch = $b_viewer, version = $n_monitor "
echo -e "Snap-block version = $n_snap"

save_my_doc()
{
    mkdir -p "/tmp/save"
    pushd "$myDoc_path"
        cp -r "Robot primitives" "/tmp/save"
        cp -r "Snap project/Snap codes" "/tmp/save"
        cp -r "Moves recorded" "/tmp/save"
        cp -r "My Pictures" "/tmp/save"
    popd
}
restore_my_doc()
{
    pushd "/tmp/save"
        cp -nr "Robot primitives" "$myDoc_path"
        cp -nr "Snap codes" "$myDoc_path/Snap project"
        cp -nr "Moves recorded" "$myDoc_path"
        cp -nr "My Pictures" "$myDoc_path"
    popd
    rm -r /tmp/save
}
bootstrap()
{
    pushd "$POPPY_ROOT/puppet-master"
        python bootstrap.py "$hostname" "$creature" "--branch" "${branch}"
        python - << EOF
import yaml
def convert(val):
    if val == 'on': return True
    else: return False
with open("$configFile") as f:
    config = yaml.load(f, Loader=yaml.SafeLoader)
    f.close()
config['robot']['firstPage'] = convert("$old_robot_firstPage")
config['robot']['autoStart'] = convert("$old_robot_autoStart")
config['robot']['camera'] = convert("$old_robot_camera")
config['robot']['virtualBot'] = "$old_robot_virtualBot"
config['info']['langage'] = "$old_info_langage"
config['wifi']['start'] = convert("$old_wifi_start")
config['wifi']['ssid'] = "$old_wifi_ssid"
config['wifi']['psk'] = "$old_wifi_psk"
config['hotspot']['start'] = convert("$old_hotspot_start")
config['hotspot']['ssid'] = "$old_hotspot_ssid"
config['hotspot']['psk'] = "$old_hotspot_psk"
with open("$configFile", "w") as f:
    yaml.dump(config, f)
    f.close()
EOF
    popd
}
update_pypot()
{
    pip install --upgrade "https://github.com/poppy-project/pypot/archive/${b_pypot}.zip"
    sed -i 's/cv2.imwrite(\"{}.png\"/cv2.imwrite(\"pictures\/{}.png\"/' $POPPY_ROOT/pypot/server/snap.py
    sed -i 's/#os.makedirs(\"pictures_path\"/os.makedirs(\"pictures\"/' $POPPY_ROOT/pypot/server/snap.py
    sed -i 's/self.moves_path=""/self.moves_path="moves\/"/' $POPPY_ROOT/pypot/server/rest.py
    sed -i 's/#os.makedirs(self.moves_path/os.makedirs(self.moves_path/g' $POPPY_ROOT/pypot/server/rest.py
}
update_creature()
{
    pushd /tmp
        wget --progress=dot:mega "https://github.com/poppy-project/$creature/archive/${b_creature}.zip" -O $creature-$b_creature.zip
        unzip -q $creature-$b_creature.zip
        rm -f $creature-$b_creature.zip
        pushd $creature-$b_creature
            pip install --upgrade software/
        popd
    popd
}
update_puppet_master()
{
    pushd "$POPPY_ROOT"
        rm -r puppet-master
        wget --progress=dot:mega "https://github.com/poppy-project/puppet-master/archive/${branch}.zip" -O puppet-master.zip
        unzip -q puppet-master.zip
        rm -f puppet-master.zip
        mv "puppet-master-${branch}" puppet-master
        pushd puppet-master
            pip install --upgrade flask pyyaml requests
            mkdir "moves"
            mkdir "pictures"
        popd
    popd
}
update_monitor()
{
    pushd "$POPPY_ROOT"
        rm -r poppy-monitor
        wget --progress=dot:mega "https://github.com/poppy-project/poppy-monitor/archive/${b_monitor}.zip" -O monitor.zip
        unzip -q monitor.zip
        rm -f monitor.zip
        mv "poppy-monitor-${b_monitor}" poppy-monitor
    popd
}
update_viewer()
{
    sudo systemctl stop poppy-viewer.service
    pushd "$POPPY_ROOT"
        rm -r poppy-viewer
        wget --progress=dot:mega "https://github.com/poppy-project/poppy-simu/archive/gh-pages${b_viewer}.zip" -O viewer.zip
        unzip -q viewer.zip
        rm -f viewer.zip
        mv "poppy-simu-gh-pages${b_viewer}" poppy-viewer
    popd
    sudo systemctl start poppy-viewer.service
}
update_snap()
{
    pushd "$POPPY_ROOT"
        rm -r snap
        wget --progress=dot:mega "https://github.com/jmoenig/Snap/archive/v${n_snap}.zip" -O snap.zip
        unzip -q snap.zip
        rm -f snap.zip
        mv "Snap-${n_snap}" snap

        #pypot_root=$(python -c "import pypot, os; print(os.path.dirname(pypot.__file__))")
        pypot_root="$POPPY_ROOT/pypot"

        # Delete snap default examples
        rm -rf snap/Examples/EXAMPLES

        # Snap projects are dynamicaly modified and copied on a local folder for acces rights issues
        # This snap_local_folder is defined depending the OS in pypot.server.snap.get_snap_user_projects_directory()
        snap_local_folder="$HOME/.local/share/pypot"

        # Link pypot Snap projets to Snap! Examples folder
        for project in $pypot_root/server/snap_projects/*.xml; do
            # Local file doesn"t exist yet if SnapRobotServer has not been started
            filename=$(basename "$project")
            cp "$project" "$snap_local_folder/"
            ln -s "$snap_local_folder/$filename" snap/Examples/
            echo -e "$filename\t$filename" >> snap/Examples/EXAMPLES
        done

        ln -s "$snap_local_folder/pypot-snap-blocks.xml" snap/libraries/poppy.xml
        echo -e "poppy.xml\tPoppy robots" >> snap/libraries/LIBRARIES
    popd
}
update_documentation()
{
    sudo systemctl stop poppy-docs.service
    pushd "$POPPY_ROOT"
        rm -r poppy-docs
        #version=$(curl --silent https://github.com/poppy-project/poppy-docs/releases/latest | sed 's#.*tag/\(.*\)\".*#\1#')
        wget --progress=dot:mega "https://github.com/poppy-project/poppy-docs/releases/download/${n_docs}/_book.zip" -O _book.zip
        unzip -q _book.zip
        rm -rf _book.zip
        mv _book poppy-docs
        rm -r "poppy-docs/es" "poppy-docs/de" "poppy-docs/nl"
    popd
    sudo systemctl start poppy-docs.service
}
echo -e " "
echo -e "\e[33m >>> Starting update <<<\e[0m"
echo -e " "
echo -e "\e[33m > Save docs \e[0m -- $(date "+%H:%M:%S") --"
save_my_doc
echo -e " "
if [ "$n_pypot" == "$v_pypot" ]; then
    echo -e " > pypot (v $v_pypot) already up to date!"
else
    echo -e "\e[33m > update: pypot \e[0m -- $(date "+%H:%M:%S") --"
    update_pypot
fi
echo -e " "
if [ "$n_creature" == "$v_creature" ]; then
    echo -e " > $creature (v $v_creature) already up to date!"
else
    echo -e "\e[33m > update: $creature \e[0m -- $(date "+%H:%M:%S") --"
    update_creature
fi
echo -e " "
if [ "$n_puppetMaster" == "$v_puppetMaster" ]; then
    echo -e " > puppet-master (v $v_puppetMaster) already up to date!"
else
    echo -e "\e[33m > update: puppet-master \e[0m -- $(date "+%H:%M:%S") --"
    update_puppet_master
fi
echo -e " "
if [ "$n_monitor" == "$v_monitor" ]; then
    echo -e " > poppy-monitor (v $v_monitor) already up to date!"
else
    echo -e "\e[33m > update_monitor \e[0m -- $(date "+%H:%M:%S") --"
    update_monitor
fi
echo -e " "
if [ "$n_viewer" == "$v_viewer" ]; then
    echo -e " > poppy-viewer (v $v_viewer) already up to date!"
else
    echo -e "\e[33m > update_viewer \e[0m -- $(date "+%H:%M:%S") --"
    update_viewer
fi
echo -e " "
if [ "$n_snap" == "$v_snap" ]; then
    echo -e " > Snap-block (v $v_snap) already up to date!"
else
    echo -e "\e[33m > update_snap \e[0m -- $(date "+%H:%M:%S") --"
    update_snap
fi
echo -e " "
if [ "$n_docs" == "$v_docs" ]; then
    echo -e " > Documentation (v $v_docs) already up to date!"
else
    echo -e "\e[33m > update_documentation \e[0m -- $(date "+%H:%M:%S") --"
    update_documentation
fi
echo -e " "
echo -e "\e[33m > Restore docs and config \e[0m -- $(date "+%H:%M:%S") --"
restore_my_doc
bootstrap
echo -e " "
echo -e "\e[33m ************************* \e[0m"
echo -e "\e[33m **** Update Complete **** \e[0m"
echo -e "\e[33m ************************* \e[0m"
echo -e " "
echo -e " Exit and restarting puppet-master service."
echo -e " Wait few seconds and go to home page."
echo -e " "
echo -e "$(date)."
sleep 3
sudo systemctl restart puppet-master.service

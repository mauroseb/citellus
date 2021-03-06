#!/usr/bin/env bash
# Description: This script contains common functions to be used by citellus plugins
#
# Copyright (C) 2018 Pablo Iranzo Gómez <Pablo.Iranzo@gmail.com>
# Copyright (C) 2018 Carsten Lichy-Bittendorf <clb@redhat.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Helper script to define location of various files.

discover_ocp_minor(){
    if is_rpm atomic-openshift >/dev/null 2>&1; then
        RPMINSTALLED=$(is_rpm atomic-openshift)
        VERSION=$(echo ${RPMINSTALLED}|cut -d "-" -f 3|cut -d "." -f 1-3)
    else
        if is_rpm atomic-openshift-node >/dev/null 2>&1; then
            RPMINSTALLED=$(is_rpm atomic-openshift-node)
            VERSION=$(echo ${RPMINSTALLED}|cut -d "-" -f 4|cut -d "." -f 1-3)
        else
            VERSION="0"
        fi
    fi
    echo ${VERSION}
}

discover_ocp_version(){
    discover_ocp_minor|cut -d "." -f 1-2
}

get_ocp_node_type(){
    OCPVERSION=$(discover_ocp_minor)
    OCPMINORVERSION=$(echo ${OCPVERSION} | awk -F "." '{print $2}')
    HNAME=$(cat ${CITELLUS_ROOT}/etc/hostname)

    NODELISTFILELIST=$(ls ${CITELLUS_ROOT}/../../*_all_nodes.out)
    for file in ${NODELISTFILELIST}; do
        NODELISTFILE=${file}
    done

    if [[ -f ${NODELISTFILE} ]] && [[ ${OCPMINORVERSION} -gt 8 ]]; then
        NODEROLE=$(grep ${HNAME} ${NODELISTFILE}| awk '{print $3}')
    elif is_rpm atomic-openshift-master >/dev/null 2>&1; then
        NODEROLE='master'
    elif [[ -f ${CITELLUS_ROOT}/etc/origin/master/master-config.yaml ]]; then
        NODEROLE='master'
    elif is_rpm atomic-openshift-node >/dev/null 2>&1; then
        NODEROLE='node'
    else
        NODEROLE='unknown'
    fi
    echo ${NODEROLE}
}

calculate_cluster_pod_capacity(){
    DEFAULT_PODS_PER_CORE=10
    DEFAULT_MAX_PODS=250

    CLUSTERNODELIST=$(find ${CITELLUS_ROOT}/../../ -maxdepth 1 -type d)

    MAXPODCLUSTER=0
    for nodes in ${CLUSTERNODELIST}; do
        if [ -d ${nodes}/sosreport-*/sos_commands ]; then
            PODS_PER_CORE=${DEFAULT_PODS_PER_CORE}
            MAX_PODS=${DEFAULT_MAX_PODS}
            NUMBER_CPU=$(grep 'CPU(s):' ${nodes}/sosreport-*/sos_commands/processor/lscpu)

            XXX=$(grep 'pods-per-core:' -A1 ${nodes}/sosreport-*/etc/origin/node/node-config.yaml)
            if [[ ! -z ${XXX} ]] ;then
                PODS_PER_CORE=( $(echo ${XXX} | awk -F "['\"]" '{print $2}') )
            fi
            ZZZ=$(grep 'max-pods:' -A1 ${nodes}/sosreport-*/etc/origin/node/node-config.yaml)
            if [[ ! -z ${ZZZ} ]] ;then
                MAX_PODS=( $(echo ${ZZZ} | awk -F "['\"]" '{print $2}') )
            fi

            NOCPU=( $(echo ${NUMBER_CPU} | awk -F " " '{print $2}') )
            MAXPOD=$( (( "$MAX_PODS" <= $NOCPU*$PODS_PER_CORE )) && echo "$MAX_PODS" || echo "$(( $NOCPU*$PODS_PER_CORE ))" )
            MAXPODCLUSTER=$(( $MAXPODCLUSTER+$MAXPOD ))
        fi
    done
    echo ${MAXPODCLUSTER}
}

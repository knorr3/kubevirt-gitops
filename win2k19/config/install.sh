#!/bin/sh

echo "Starting install script"
cd /scripts

oc apply -f windows-install-vm.yaml
echo "Applied VM, waiting for VM to start"
sleep 5
vm_ready=$(oc get vm windows-install -o jsonpath='{.status.ready}')
while [ "$vm_ready" != "true" ]
do
    sleep 10
    vm_ready=$(oc get vm windows-install -o jsonpath='{.status.ready}')
done

echo "VM is started. Waiting for VM to finish successfully."
vm_phase=$(oc get vm windows-install -o jsonpath='{.status.printableStatus}')
while [ "$vm_phase" != "Stopped" ]
do
    sleep 30
    vm_phase=$(oc get vm windows-install -o jsonpath='{.status.printableStatus}')
done

echo "VM has finished installing"
oc apply -f clone-boot-source.yaml
echo "Applied DataVolume to clone boot source image"

sleep 5
dv_phase=$(oc -n openshift-virtualization-os-images get dv win2k19 -o jsonpath='{.status.phase}')
while [ "$dv_phase" != "Succeeded" ]
do
    sleep 10
    dv_phase=$(oc -n openshift-virtualization-os-images get dv win2k19 -o jsonpath='{.status.phase}')
    echo $dv_phase
done

echo "Cleaning up"
oc delete -f windows-install-vm.yaml

my_app_name=$(oc get cm windows-install-scripts -o jsonpath='{.metadata.labels.app\.kubernetes\.io/instance}')

echo "Finished"

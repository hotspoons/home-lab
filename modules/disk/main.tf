resource "ovirt_disk" "disk" {
  name              = "${var.name}"
  alias             = "${var.name}"
  size              = "${var.size}"
  format            = "${var.format}"
  storage_domain_id = "${var.storage_domain_id}"
  sparse            = "${var.sparse}"
  shareable         = "${var.shareable}"
}

resource "ovirt_disk_attachment" "diskattachment" {
  vm_id                = "${var.vm_id}"
  disk_id              = "${ovirt_disk.disk.id}"
  active               = "${var.active}"
  bootable             = "${var.bootable}"
  interface            = "${var.interface}"
  read_only            = "${var.read_only}"
  use_scsi_reservation = "${var.use_scsi_reservation}"
}

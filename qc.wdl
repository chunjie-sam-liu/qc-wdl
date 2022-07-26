
workflow QC {
  Array[File] inputFiles
  String outdir

  String pairedORsingle = "paired"

  Int nthread = 10

  Int machine_mem_gb = 4
  Int disk_space_gb = 50
  Boolean use_ssd = false
  String docker_image

  scatter (inputFile in inputFiles) {
    call qc_bam {
      input:
      bam = inputFile,
      outdir = outdir,
      pairedORsingle = pairedORsingle,
      nthread = nthread,
      machine_mem_gb = machine_mem_gb,
      disk_space_gb = disk_space_gb,
      use_ssd = use_ssd,
      docker_image = docker_image
    }
  }
  call gatherbam {
    input:
    outfile = qc_bam.outfile,
    bam_name = qc_bam.bam_name,
    outdir = outdir,
    pairedORsingle = pairedORsingle,
    nthread = nthread,
    machine_mem_gb = machine_mem_gb,
    disk_space_gb = disk_space_gb,
    use_ssd = use_ssd,
    docker_image = docker_image
  }




  meta {
    author: "Chun-Jie Liu"
    email : "chunjie.sam.liu@gmail.com"
    description: "WDL workflow on AnVIL for rMATS turbo v4.1.2(/4.1.1) developed in Dr. Yi Xing's lab"
  }
}

task qc_bam {
  File bam
  String docker_image
  String outdir
  Int nthread
  Int machine_mem_gb
  Int disk_space_gb
  Boolean use_ssd

  command {
    fastqc -t $nthread -o ${outdir} ${bam}
  }

  runtime {
    docker: docker_image
    memory: machine_mem_gb
    disks: "local-disk " + disk_space_gb + if use_ssd then " SSD" else " HDD"
  }

  output {
    Array[File] outfile = glob("*_fastqc.zip")
    String bam_name = basename("${bam}")
  }
}

task gatherbam {
  Array[Array[File]] outfile
  Array[String] bam_name
  Array[File] newoutfile = flatten(outfile)
  Array[File] newnewoutfile = flatten([newoutfile])
  String docker_image
  String outdir
  Int nthread
  Int machine_mem_gb
  Int disk_space_gb
  Boolean use_ssd

  command {
    tar czf ${outdir}.tar.gz ${outdir}
  }

  runtime {
    docker: docker_image
    memory: machine_mem_gb
    disks: "local-disk " + disk_space_gb + if use_ssd then " SSD" else " HDD"
  }

  output {
    File outfile = "${outdir}.tar.gz"
  }
}
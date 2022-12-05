workflow IDXSTATS {
  Array[File] inputFiles
  String outdir

  String pairedORsingle = "paired"

  Int nthread = 2

  Int machine_mem_gb = 10
  Int disk_space_gb = 80
  Boolean use_ssd = false
  String docker_image


  scatter (inputFile in inputFiles) {
    call idxstats_bam {
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

  call gather_idxstats {
    input:
      outfile = idxstats_bam.outfile,
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

task idxstats_bam {
  File bam
  String docker_image
  String outdir
  Int nthread
  Int machine_mem_gb
  Int disk_space_gb
  Boolean use_ssd
  String pairedORsingle
  String bamname = basename(bam, ".bam")

  command {
    samtools idxstats --threads=${nthread} ${bam} > ${bamname}.idxstats
  }
  runtime {
    docker: docker_image
    memory: machine_mem_gb + " GB"
    disks: "local-disk " + disk_space_gb + if use_ssd then " SSD" else " HDD"
  }
  output {
    File outfile = "${bamname}.idxstats"
  }
}
task gather_idxstats {
  Array[File] outfile
  String docker_image
  String outdir
  Int nthread
  Int machine_mem_gb
  Int disk_space_gb
  Boolean use_ssd
  String pairedORsingle

  command {
    mkdir ${outdir}
    for file in ${sep=" " outfile}
    do
      cp $file ${outdir}
    done
    tar czf ${outdir}.tar.gz ${outdir}
  }
  runtime {
    docker: docker_image
    memory: machine_mem_gb + " GB"
    disks: "local-disk " + disk_space_gb + if use_ssd then " SSD" else " HDD"
  }
  output {
    File finaloutfile = "${outdir}.tar.gz"
  }
}
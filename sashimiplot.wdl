workflow IDXSTATS {
  Array[File] inputFiles
  File gtf
  File input_bams
  String outdir

  String pairedORsingle = "paired"

  Int nthread = 2

  Int machine_mem_gb = 10
  Int disk_space_gb = 80
  Boolean use_ssd = false
  String docker_image


  call idxstats_bam {
    input:
      bams = inputFiles,
      gtf = gtf,
      input_bams = input_bams,
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

task sashimiplot {
  Array[File] bams
  File gtf
  File input_bams
  String docker_image
  String outdir
  Int nthread
  Int machine_mem_gb
  Int disk_space_gb
  Boolean use_ssd
  String pairedORsingle
  # String bamname = basename(bam, ".bam")

  command {
    /ggsashimi.py -b ${input_bams} -c chr2:201276826-201285317 -g ${gtf} -M 10 -C 3 -O 3 -A mean --shrink --alpha 0.25 --base-size=20 --ann-height=4 --height=3 --width=18 -o ggsashimiplot.pdf
    mkdir ${outdir}
    cp ggsashimiplot.pdf ${outdir}
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

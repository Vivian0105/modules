process PRESTO_ASSEMBLEPAIRS {
    tag "$meta.id"
    label 'process_long'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/presto:0.7.9--pyhdfd78af_0':
        'quay.io/biocontainers/presto:0.7.9--pyhdfd78af_0' }"

    input:
    tuple val(meta), path(R1_reads), path(R2_reads)

    output:
    tuple val(meta), path("*_assemble-pass.fastq.gz"), emit: reads
    path "*_command_log.txt", emit: logs
    path("*_table.tab"), emit: log_tab
    tuple val("${task.process}"), val('presto'), eval('AssemblePairs.py --version | grep -o "[0-9][0-9.]*" | head -n 1'), emit: versions_presto, topic: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def args2 = task.ext.args2 ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    AssemblePairs.py align -1 ${R1_reads} -2 ${R2_reads} --nproc ${task.cpus} \\
        $args \\
        --outname ${prefix} --log ${meta.id}.log > ${prefix}_command_log.txt

    ParseLog.py -l ${prefix}.log $args2 -f ID LENGTH ERROR PVALUE
    """

    stub:
    def args = task.ext.args ?: ''
    def args2 = task.ext.args2 ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    echo $args
    
    touch ${prefix}_assemble-pass.fastq.gz \\
          ${prefix}_command_log.txt
          ${prefix}_table.tab
    """
}
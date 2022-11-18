def asString (args) {
    s = ""
    if (args.size()>0) {
        if (args[0] != 'none') {
            for (param in args.keySet().sort()){
                s = s + ",'"+param+"'='"+args[param]+"'"
            }
        }
    }
    return s
}

process SINGLE_CELL_QC {
    tag 'all_single_cell'
    label 'immcantation'
    label 'process_medium'
    label 'enchantr'


    conda (params.enable_conda ? "bioconda::r-enchantr=0.0.3" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/r-enchantr:0.0.3--r42hdfd78af_1':
        'quay.io/biocontainers/r-enchantr:0.0.3--r42hdfd78af_1' }"

    input:
    tuple val(meta), path(tabs)

    output:
    path("*/*scqc-pass.tsv"), emit: tab // sequence tsv in AIRR format
    path("*_command_log.txt"), emit: logs //process logs
    path("*_report"), emit: report
    path("versions.yml"), emit: versions

    script:
    def args = asString(task.ext.args) ?: ''
    """
    echo "${tabs.join('\n')}" > tabs.txt
    Rscript -e "enchantr::enchantr_report('single_cell_qc', \\
        report_params=list('input'='tabs.txt',\\
        'outdir'=getwd(), \\
        'log'='all_reps_scqc_command_log'  ${args} ))"

    echo "${task.process}": > versions.yml
    Rscript -e "cat(paste0('  enchantr: ',packageVersion('enchantr'),'\n'))" >> versions.yml

    mv enchantr all_reps_scqc_report
    """
}

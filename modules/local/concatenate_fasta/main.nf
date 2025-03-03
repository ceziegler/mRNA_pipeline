process CONCATENATE_FASTA {
    label "process_low"

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-8849acf39a43cdd6c839a369a74c0adc823e2f91:ab110436faf952a33575c64dd74615a84011450b-0' :
        'biocontainers/mulled-v2-8849acf39a43cdd6c839a369a74c0adc823e2f91:ab110436faf952a33575c64dd74615a84011450b-0' }"

    input:
    path fasta
    path plasmid_ref

    output:
    path "concatenated.fasta" , emit: fasta 

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    # Decompress any gzipped input files
    find . -name "*.gz" -exec gunzip {} \\;
    
   # First copy/handle the main fasta
    if [[ "${fasta}" == *.gz ]]; then
        gunzip -c ${fasta} > main.fasta
    else
        cat ${fasta} > main.fasta
    fi
    
    # Create list of uncompressed plasmid files
    plasmid_files=""
    for file in ${plasmid_ref}; do
        if [[ "\$file" == *.gz ]]; then
            base=\$(basename "\$file" .gz)
            plasmid_files="\$plasmid_files \$base"
        else
            plasmid_files="\$plasmid_files \$file"
        fi
    done
    
    # Concatenate all fasta files
    cat main.fasta \$plasmid_files > concatenated.fasta

    """
}
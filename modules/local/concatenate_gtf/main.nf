process CONCATENATE_GTF {
    label "process_low"

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-8849acf39a43cdd6c839a369a74c0adc823e2f91:ab110436faf952a33575c64dd74615a84011450b-0' :
        'biocontainers/mulled-v2-8849acf39a43cdd6c839a369a74c0adc823e2f91:ab110436faf952a33575c64dd74615a84011450b-0' }"

    input:
    path gtf
    path plasmid_ref

    output:
    path "concatenated.gtf", emit: gtf  

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    # Decompress main GTF if needed
    if [[ "${gtf}" == *.gz ]]; then
        gunzip -c ${gtf} > main.gtf
    else
        cp ${gtf} main.gtf
    fi

    # Prepare plasmid GTF files and ensure valid attributes
    touch plasmid_combined.gtf
    for file in ${plasmid_ref}; do
        # Skip if file is empty or doesn't exist
        [ ! -f "\$file" ] && continue

        # Decompress if gzipped
        if [[ "\$file" == *.gz ]]; then
            gunzip -c "\$file" > temp.gtf
        else
            cp "\$file" temp.gtf
        fi

        # Add gene_id if missing
        awk -F'\t' '{
            if (\$0 ~ /^#/) next;  # Skip comments
            if (\$9 !~ /gene_id/) {
                name = \$1 "_gene_" NR;  # Unique gene_id based on seqname and line number
                \$9 = "gene_id \"" name "\"; " \$9;
            }
            print \$0
        }' OFS='\t' temp.gtf >> plasmid_combined.gtf
        rm temp.gtf
    done

    # Concatenate main and plasmid GTFs
    cat main.gtf > concatenated.gtf
    if [ -s plasmid_combined.gtf ]; then
        grep -v "^#" plasmid_combined.gtf >> concatenated.gtf
    fi
    """
}
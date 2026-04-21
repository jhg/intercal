# fish completion for intercal
# Install to ~/.config/fish/completions/intercal.fish or /usr/share/fish/vendor_completions.d/

complete -c intercal -f
complete -c intercal -s o -l output -d 'Output binary path' -r -F
complete -c intercal -d 'INTERCAL source file' -r -F -a "(__fish_complete_suffix .i)"

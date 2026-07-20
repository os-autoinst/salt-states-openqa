import subprocess

def rebootmgr_version():
    """
    Returns the installed version of rebootmgr directly via RPM
    to bypass Salt loader race conditions.
    """
    # Initialize the grain dictionary with a default 0 value
    grains = {'rebootmgr_version': '0'}
    
    try:
        # Query RPM directly for the package version
        result = subprocess.run(
            ['rpm', '-q', '--queryformat', '%{VERSION}', 'rebootmgr'],
            capture_output=True,
            text=True
        )
        
        # If the command succeeded (package is installed), assign the version
        if result.returncode == 0:
            grains['rebootmgr_version'] = result.stdout.strip()
            
    except Exception:
        pass
        
    return grains

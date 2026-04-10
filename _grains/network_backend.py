import os

def network_backend():
    '''
    Returns the basename of the service linked to network.service,
    stripping the .service suffix.
    '''
    grains = {}
    target_link = '/etc/systemd/system/network.service'
    
    try:
        if os.path.islink(target_link):
            # Resolve the symlink (readlink)
            full_path = os.readlink(target_link)
            # Get the filename and strip '.service' (basename -s .service)
            backend_name = os.path.basename(full_path)
            if backend_name.endswith('.service'):
                backend_name = backend_name[:-8] # Remove '.service'
            
            grains['network_backend'] = backend_name
    except Exception:
        pass
        
    return grains

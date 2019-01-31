function images = findImagesInFolder(folder,fileType,frontConstraint)

    if nargin > 2 && ~isempty(frontConstraint)
        a = dir([folder frontConstraint '*' fileType ]);
    else
        a = dir([folder '*' fileType ]);
    end
    
    images = {a(:).name};
    
    if min(size(images)) == 0
        images = {};
    end
    

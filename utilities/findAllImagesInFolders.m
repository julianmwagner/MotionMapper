function images = findAllImagesInFolders(folder,fileType,frontConstraint)

    if nargin < 2 || isempty(fileType)
        fileType = '.tif';
    end
    
    if nargin < 3 || isempty(frontConstraint)
        frontConstraint = [];
    end

    
    MAXIMAGES = 100000;
    count = 1;
    images = cell(MAXIMAGES,1);
    
    currentDirectory = dir(folder);
    b = {currentDirectory(:).name};
    currentDirs = b([currentDirectory(:).isdir] & returnCellLengths(b)>2);
    
    a = findImagesInFolder(folder,fileType,frontConstraint);
    for i=1:length(a)      
        images{i} = [folder slashVal() a{i}];
        count = count + 1;
    end
    
    if ~isempty(currentDirs)
        for i=1:length(currentDirs)
            a = findImagesInFolder([folder slashVal() currentDirs{i} slashVal()],fileType,frontConstraint);
            for j=1:length(a)
                images{count} = [folder slashVal() currentDirs{i} slashVal() a{j}];
                count = count + 1;
            end
        end
    end

    images = images(1:count-1);
    
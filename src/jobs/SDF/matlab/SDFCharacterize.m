function SDFCharacterize(userId, jobId, jobType, jobSrcDir, jobDir, webBaseUri,input_type,file_name)

%%% Input Types %%
% 1 : Single JPEG Image
% 2 : ZIP file containing JPEG images
% 3 : Image in .mat file
%% Added changed
% Accept Odd shaped images 
% Binarize raw jpg image
rc=0;
try
    path_to_read = [jobSrcDir,'/'];
    path_to_write = [jobSrcDir,'/output'];
    mkdir(path_to_write);
    
    writeError([path_to_write, '/errors.txt'], ''); % ensure that errors.txt exists
    
    %% Specify import function according to input option
    switch str2num(input_type)
        case 1
            img = imread([path_to_read,file_name]); % read the incming target and store pixel values
            if length(size(img)) > 2
                imwrite(img(:,:,1:3),[path_to_write,'/','Input1.jpg'])
            elseif length(size(img)) > 1
                imwrite(img,[path_to_write,'/','Input1.jpg'])
            else
                writeError([path_to_write, '/errors.txt'], ['failed to read image file: ', file_name]);
                rc = 97
                exit(rc)
                
            end
            
        case 2
            unzip([path_to_read,file_name],[path_to_write,'/input']);
        case 3
            path=[path_to_read,file_name];
            k=load(path);
            [no_need,f_name,ext]=fileparts(file_name);
            try
                img = getfield(k,f_name);
            catch ex
                rc = 98;
                msg = getReport(ex);
                writeError([path_to_write, '/errors.txt'], 'The variable name inside the material file shold be the same as the name of the file. Technical details below:');
                
                writeError([path_to_write, '/errors.txt'], msg);
                writeError([path_to_write, '/errors.txt'], sprintf('\n'));
                exit(rc);
            end
            % imwrite(img,[path_to_write,'/','Input1.jpg']);
            imwrite(256*img,[path_to_write,'/','Input1.jpg']);
    end
    
    if str2num(input_type) ~= 2
        %% SDF code - Shuangchen & Yichi
        % img_original - binary original image
        
        if length(size(img)) > 2
            img_original = img(:,:,1);
        else
            img_original = img;
        end
        %%Umar added to deal with odd shaped images
        
        md=min(size(img_original));
        img_original=img_original(1:md,1:md);
        
        %% Umar added to check and binarize the image using Otsu 02/27/2019
        if max(img_original(:))>1
            Target = double(img_original);
            Target = Target/256; %
            level = graythresh(Target);
            img_original = im2bw(Target,level);
        end
        %%
        vf = mean(img_original(:));
        % pixel = size(img_original,1);
        sdf2d = fftshift(abs(fft2(img_original-vf)).^2); % 2D sdf
        sdf1d = FFT2oneD(sdf2d); % 1D sdf ** removed transpose to make it a coloumn vector **
        
        csvwrite([path_to_write,'/SDF_2D.csv'],sdf2d);
        csvwrite([path_to_write,'/SDF_1D.csv'],sdf1d);
        
        % plot 2d SDF and save image
        figure('color',[1,1,1])
        hold on;
        clims = [1e4 7e5];
        map = [0.0, 0, 0
            1.0, 0.5, 0
            1.0, 1.0, 0
            1.0, 0, 0];
        imagesc(sdf2d,clims); colormap(map);
        xlim([0 size(img_original,1)]); ylim([0 size(img_original,2)]);
        set(gca,'xtick',[]); set(gca,'ytick',[]);
        saveas(gcf,[path_to_write,'/SDF_2D.jpg']);
        hold off;
    else
        [er]=zip_file_processing_SDFchar(path_to_write);
        if er>0
            writeError([path_to_write, '/errors.txt'], 'Error in reading some of the files in the zip folder. Please make sure all files inside are of the appropriate image format e.g. JPG or PNG ');
        end
    end
    
    %% ZIP files %%
    zip([path_to_write,'/Results.zip'],{'*'},path_to_write);
catch ex
    rc = 99;
    exit(rc);
end
    function writeError(file, msg)
        f = fopen(file,'a+');
        fprintf(f, '%s\n', msg);
        fclose(f);
    end
end



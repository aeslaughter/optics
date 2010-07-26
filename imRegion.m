classdef imRegion < hgsetget
% imRegion creates a class for a selected region of imObject image
%__________________________________________________________________________
% SYNTAX:
%   imRegion(obj,type,func)
%
% DESCRIPTION:
%   imRegion(obj,type,func)
%__________________________________________________________________________
    
% DEFINE THE PUBLIC PROPERTIES    
properties
    parent; % Handle of the parent imObject
    position; % Position of the region
    type = 'work'; % Type of region (used to define color)
    func = 'imrect'; % Function defining the shape of region to create
    color = 'b'; % Color of the region
    label; % Label to place within the region for identification
    labelposition; % The coordinates for positioning the label
    image; % Image filled with NaN's outside of the selection
end

% DEFINE THE PRIVE PROPERTIES
properties (SetAccess = private)
    texthandle; % Handle of the the text object created 
    imroi; % Handle of the imroi region created
end

% DEFINE THE METHODS
methods
    % imRegion: executes upon the creation of the object
    function obj = imRegion(imobj,type,func)
        % Assign the user supplied input
        obj.parent = imobj;
        obj.func = func;
        obj.type = type;
        
        % Define the color based on the type
        if strcmpi(obj.type,'white'); obj.color = 'r'; end
        
        % Create the region
        obj.createregion;
    end

    % SET.FUNC: operates when the func property is changed
    function obj = set.func(obj,input)
        switch lower(input)
            case {'e','ellipse','imellipse'};      obj.func = 'imellipse';
            case {'f','freehand','imfreehand'};    obj.func = 'imfreehand';
            case {'p','poly','polygon','impoly'};  obj.func = 'impoly';    
            case {'r','rect','rectangle','imrect'};obj.func = 'imrect';
        end     
    end
    
    % CREATEREGION: builds the imroi region
    function obj = createregion(obj,varargin)
        % Define the region using the im* functions  
        ax = obj.parent.imaxes;
        if ~isempty(varargin) && strcmpi(varargin{1},'load');
             h = feval(obj.func,ax,obj.position);
            %obj.position = getPosition(h);
        else
            h = feval(obj.func,ax);
            obj.position = wait(h);
        end
        obj.imroi = h; % Assigns the region handle to the imroi property

        % Set the color and limit the region to the image extents
        setColor(h,obj.color);
        fcn = makeConstrainToRectFcn(obj.func,get(ax,'XLim'),...
            get(imgca,'YLim'));
        setPositionConstraintFcn(h,fcn); 

        % Freeze the region position
        obj.freeze;
    end    
    
    % GETREGION: collects the image information
    function obj = getRegion(obj,varargin)
        % Disable the figure
        H = findobj('enable','on');
        set(H,'enable','off');
        drawnow;
          
        % Get the image information and develop the region mask
        I = double(obj.parent.image); % The image
        N = numel(I); % Number of pixels
        c = size(I,3); % Number of colors in image

        if ~isempty(varargin) && varargin{1} && ~isempty(obj.parent.norm);
           theNorm = obj.parent.norm;
           for i = 1:c;
              I(:,:,i) = I(:,:,i)/theNorm(i); 
           end
        end
        
        R = createMask(obj.imroi); % The image mask of the region       
        R = repmat(R,[1,1,c]); % Expand the image mask
                
        % Apply the mask to the image, filling in NaN's
        Rind = reshape(R,[1,1,N]);
        Iind = reshape(I,[1,1,N]);
        Iind(~Rind) = NaN;
        
        % Return the region, as a double
        obj.image = reshape(Iind,size(I));
        
        % Enable the figure
        set(H,'enable','on');
    end
 
    % ADDLABEL: inserts the region label
    function obj = addlabel(obj,input)
        % Define the im axes handle and remove existing label
        ax = imgca(obj.parent.imhandle);
        if ishandle(obj.texthandle); delete(obj.texthandle); end
    
        % Gather the label and label position
        obj.label = input;
        X = obj.labelposition;
    
        % Insert the text object
        obj.texthandle = text(X(1),X(2),obj.label,'Color',obj.color,...
            'Margin',3,'parent',ax,'VerticalAlignment','bottom',...
            'HorizontalAlignment','left');   
    end
     
    % FREEZE: fixes the region in place
    function obj = freeze(obj)
        % Gather the handle and position
        h = obj.imroi;
        pos = obj.position;
    
        % Gathers the ellipse verticies
        if strcmpi(obj.func,'imellipse');
            pos = getVertices(h);
        end
        
        % Compute the X,Y extents for used with "makeConstrainToRectFcn:    
        switch obj.func
            case 'imrect';
                X = [pos(1),pos(1)+pos(3)]; Y = [pos(2),pos(2)+pos(4)];
            case {'impoly','imellipse','imfreehand'};
                X = [min(pos(:,1)), max(pos(:,1))]; 
                Y = [min(pos(:,2)), max(pos(:,2))]; 
        end
    
        % Restrict the region so it cannot be resized
        switch obj.func
          case 'impoly';  setVerticesDraggable(h,false)
          case {'imrect','imellipse'}; setResizable(h,false);
          case 'imfreehand'; obj.func = 'impoly'; % Needed to load freehand 
        end

        % Implement the constraints
        fcn = makeConstrainToRectFcn(obj.func,X,Y);
        setPositionConstraintFcn(h,fcn); 
     
        % Assign the label position
        switch obj.func
            case {'imrect','imfreehand'};
                obj.labelposition = [X(2),Y(2)];
            case {'impoly','imellipse'};
                obj.labelposition = pos(round(end/2),:);
        end
    end
    
    % DELETE: removes the imroi object and the text label
    function delete(obj)
        if isobject(obj.imroi); delete(obj.imroi); end
        if ishandle(obj.texthandle); delete(obj.texthandle); end
    end
end
end

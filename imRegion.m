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
    position; % Position of the region
    type = 'work'; % Type of region (used to define color)
    func = 'imrect'; % Function defining the shape of region to create
    color = 'b'; % Color of the region
    label; % Label to place within the region for identification
    labelposition; % The coordinates for positioning the label
end

% DEFINE THE PRIVE PROPERTIES
properties (SetAccess = private, Transient = true)
    parent; % Handle of the parent imObject
    texthandle; % Handle of the the text object created 
    imroi; % Handle of the imroi region created
end

% DEFINE THE METHODS
methods
    % imRegion: executes upon the creation of the object
    function obj = imRegion(imobj,type,func,varargin)
        % Assign the user supplied input
        obj.parent = imobj;
        obj.func = func;
        obj.type = type;
        
        % Define the color based on the type
        if strcmpi(obj.type,'white'); obj.color = 'r'; end
        
        % Assign position directly (used with impoint)
        if ~isempty(varargin);
            obj.position = varargin{1};
        end
        
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
            case {'impoint'};                      obj.func = 'impoint';
        end     
    end
    
    % CREATEREGION: builds the imroi region
    function obj = createregion(obj,varargin)
        % imObject handle is input when loading regions
        if nargin == 2; obj.parent = varargin{1}; end
        
        % Define the region using the im* functions  
        ax = obj.parent.imaxes;
        if ~isempty(obj.position);
             h = feval(obj.func,ax,obj.position);
        else
            h = feval(obj.func,ax);
            obj.position = wait(h);
        end
        obj.imroi = h; % Assigns the region handle to the imroi property

        % Set the color and limit the region to the image extents
        if ~isvalid(h); return; end
        setColor(h,obj.color);
        fcn = makeConstrainToRectFcn(obj.func,get(ax,'XLim'),...
            get(imgca,'YLim'));
        setPositionConstraintFcn(h,fcn); 

        % Freeze the region position
        obj.freeze;
        
        % Add the label, if not isempty
        if ~isempty(obj.label);
           obj.addlabel(obj.label); 
        end
    end     
    % GETREGIONMASK: returns an image mask
    
    function mask = getRegionMask(obj)
        if ~isvalid(obj.imroi); mask = []; return; end
        mask = createMask(obj.imroi); % The image mask of the region
        mask = reshape(mask,[],1); % Organizes the mask in columns 
    end
     
    % ADDLABEL: inserts the region label
    function obj = addlabel(obj,input)
        % Add label in the case of impoint
        if strcmpi(obj.func,'impoint');
            obj.imroi.setString(input);
            return;
        end
        
        % Define the im axes handle and remove existing label
        ax = imgca(obj.parent.imhandle);
        if ishandle(obj.texthandle); delete(obj.texthandle); end
        if isempty(input); return; end % Return if the label is empty
    
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
            case 'impoint';
                X = [pos(2),pos(2)]; Y = [pos(1),pos(1)];
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
        if isvalid(obj.imroi); delete(obj.imroi); end
        if ishandle(obj.texthandle); delete(obj.texthandle); end
    end
end
end

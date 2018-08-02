unit ModuleManager;

interface
uses
    System.SysUtils, System.Generics.Collections, System.Classes
    //,FMX.Platform
    //,FMX.Types
    ;
type
  TModule = class
  private
    FInstance: TObject;
    FType: TClass;
    FIsOwner: Boolean;
  public
    constructor Create(AType: TClass; AInstance: TObject = nil;
        AIsOwner: Boolean = true);
    destructor Destroy; override;

    procedure Update(AInstance: TObject = nil);
    procedure Remove;

    function IsAlive: Boolean;
    function GetInstance: TObject; overload;
    function GetInstance(AOwner: TComponent): TObject; overload;

    property IsOwner: Boolean read FIsOwner write FIsOwner;
  end;

  TModuleManager = class
  private
    class var
        FInstance:  TModuleManager;
  private
    FModules: TDictionary<TGUID, TModule>;
  public
    class constructor Create;
    class destructor Destroy;
    class property Instance: TModuleManager read FInstance;
  public
    constructor Create;
    destructor Destroy; override;

    procedure RegisterModule(const AServiceGUID: TGUID; const AType: TClass;
         AInstance: TObject = nil; AIsOwner: Boolean = true);
    procedure UnregisterModule(const AServiceGUID: TGUID);
    procedure RemoveModule(const AServiceGUID: TGUID);
    procedure RemoveModuleRef(const AServiceGUID: TGUID);

    procedure UpdateModule(const AServiceGUID: TGUID; AInstance: TObject);

    function GetModule(const AServiceGUID: TGUID): TObject; overload;
    function GetModule<T: IInterface>(const AServiceGUID: TGUID): T; overload;
    function SupportsModule(const AServiceGUID: TGUID): Boolean; overload;
    function SupportsModule(const AServiceGUID: TGUID; out AService): Boolean; overload;
    function SupportsModule(const AServiceGUID: TGUID; out AService; AClass: TClass): Boolean; overload;

    function GetAllModules: TArray<TGUID>;
  end;
implementation

{ TModuleChecker }

constructor TModuleManager.Create;
begin
  inherited;
    FModules:= TObjectDictionary<TGUID, TModule>.Create([doOwnsValues]);
end;

destructor TModuleManager.Destroy;
begin
    FreeAndNil(FModules);
end;

function TModuleManager.GetAllModules: TArray<TGUID>;
var
    lList: TList<TGUID>;
    lPair: TPair<TGUID, TModule>;
begin
    lList := TList<TGUID>.Create;
    try
        for lPair in FModules do
            if lPair.Value.IsAlive then
                lList.Add(lPair.Key);
        Result := lList.ToArray;
    finally
        FreeAndNil(lList);
    end;
end;

function TModuleManager.GetModule(const AServiceGUID: TGUID): TObject;
var
    lModule: TModule;
begin
    SupportsModule(AServiceGUID, Result);
end;

function TModuleManager.GetModule<T>(const AServiceGUID: TGUID): T;
begin
    SupportsModule(AServiceGUID, Result);
end;

procedure TModuleManager.RegisterModule(const AServiceGUID: TGUID;
  const AType: TClass; AInstance: TObject; AIsOwner: Boolean);
begin
    FModules.Add(AServiceGUID, TModule.Create(AType, AInstance, AIsOwner));
end;

procedure TModuleManager.RemoveModule(const AServiceGUID: TGUID);
begin
  if FModules.ContainsKey(AServiceGUID) then
    FModules.Items[AServiceGUID].Remove;
end;

procedure TModuleManager.RemoveModuleRef(const AServiceGUID: TGUID);
begin
  if FModules.ContainsKey(AServiceGUID) then
    FModules.Items[AServiceGUID].Update;
end;

function TModuleManager.SupportsModule(const AServiceGUID: TGUID): Boolean;
begin
  Result := FModules.ContainsKey(AServiceGUID);
end;

function TModuleManager.SupportsModule(const AServiceGUID: TGUID; out AService;
  AClass: TClass): Boolean;
begin
    Result := SupportsModule(AServiceGUID, AService);
end;

function TModuleManager.SupportsModule(const AServiceGUID: TGUID;
  out AService): Boolean;
begin
  Result := false;
  if FModules.ContainsKey(AServiceGUID) then
  begin
    Result := Supports(FModules.Items[AServiceGUID].GetInstance(nil), AServiceGUID, AService)
  end
  else
  begin
    Pointer(AService) := nil;
    Result := False;
  end;
end;

procedure TModuleManager.UnregisterModule(const AServiceGUID: TGUID);
begin
    FModules.Remove(AServiceGUID);
end;

procedure TModuleManager.UpdateModule(const AServiceGUID: TGUID;
  AInstance: TObject);
begin
  if FModules.ContainsKey(AServiceGUID) then
    FModules.Items[AServiceGUID].Update(AInstance);
end;

class constructor TModuleManager.Create;
begin
    if (FInstance = nil) then
    begin
        FInstance := TModuleManager.Create;
    end;
end;

class destructor TModuleManager.Destroy;
begin
    FreeAndNil(FInstance);
end;

{ TModule }

constructor TModule.Create(AType: TClass; AInstance: TObject;
        AIsOwner: Boolean);
begin
    FType := AType;
    FInstance := AInstance;
    FIsOwner := AIsOwner;
end;

function TModule.GetInstance: TObject;
var
    lClass: TObject;
begin
    if not IsAlive then
        FInstance := FType.Create;
    Result := FInstance;
end;

destructor TModule.Destroy;
begin
    if IsOwner then
        Remove;
  inherited;
end;

function TModule.GetInstance(AOwner: TComponent): TObject;
begin
    if not IsAlive and FType.InheritsFrom(TComponent) then
      FInstance := TComponentClass(FType).Create(AOwner)
    else
      GetInstance;
    Result := FInstance;
end;

function TModule.IsAlive: Boolean;
begin
    Result := Assigned(FInstance);
end;

procedure TModule.Remove;
begin
    FreeAndNil(FInstance);
end;

procedure TModule.Update(AInstance: TObject);
begin
    FInstance := AInstance;
end;

end.


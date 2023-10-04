unit UTANQUES;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, SvcMgr, Dialogs,
  ScktComp, OoMisc, AdPort, IniFiles, DB, RxMemDS, ExtCtrls, ULIBGRAL, CRCs,
  uLkJSON, Variants, IdHashMessageDigest, IdHash, ActiveX, ComObj;

const
      idSOH = #1;
      idSTX = #2;
      idETX = #3;
      idACK = #6;
      idNAK = #21;

type
  Togcvtanques = class(TService)
    ServerSocket1: TServerSocket;
    pSerial: TApdComPort;
    TM_Tanques: TRxMemoryData;
    TM_TanquesCLAVE: TIntegerField;
    TM_TanquesVOLUMEN: TFloatField;
    TM_TanquesPORLLENAR: TFloatField;
    TM_TanquesVOLUMENAGUA: TFloatField;
    TM_TanquesTEMPERATURA: TFloatField;
    TM_TanquesESTATUS: TStringField;
    Timer1: TTimer;
    TM_Entradas: TRxMemoryData;
    TM_EntradasTANQUE: TIntegerField;
    TM_EntradasVOLUMENININETO: TFloatField;
    TM_EntradasVOLUMENFINNETO: TFloatField;
    TM_EntradasVOLUMENINIBRUTO: TFloatField;
    TM_EntradasVOLUMENFINBRUTO: TFloatField;
    TM_EntradasTEMPERATURA: TFloatField;
    TM_EntradasFECHAHORAINI: TDateTimeField;
    TM_EntradasFECHAHORAFIN: TDateTimeField;
    Timer2: TTimer;
    TM_TanquesVOLUMENTC: TFloatField;
    procedure ServiceExecute(Sender: TService);
    procedure ServerSocket1ClientRead(Sender: TObject;
      Socket: TCustomWinSocket);
    procedure Timer1Timer(Sender: TObject);
    procedure pSerialTriggerAvail(CP: TObject; Count: Word);
    procedure Timer2Timer(Sender: TObject);
  private
    { Private declarations }
    function InventarioTanques(mensaje:string):string;
    function EntradasTanques(tanque:Integer):string;
    function IniciaPSerial(datosPuerto:string):string;
    function IniciaTanques(tanques:TlkJSONbase):string;
    function GuardarLog: string;
    function BorrarLog: string;
    function ObtenerLog(r:Integer): string;
    function ObtenerLogPetRes(r:Integer): string;
    function GuardarLogPetRes: string;
    function Detener: string;
    function Iniciar: string;
    function ObtenerEstado: string;
    function Inicializar(json:string): string;
    procedure Responder(socket:TCustomWinSocket;resp:string);
    function Shutdown: string;
    function Terminar: string;
    function Login(mensaje: string): string;
  public
    tipoTanques:Integer;
    tanquesActivos:string;
    LineaBuff,
    LineaProc:string;
    ListaLog:TStringList;
    ListaLogPetRes:TStringList;
    SwTimer1:boolean;
    ContadorAlarma,
    ContadorAlarma3,
    ContadorAlarma2,
    ContRec,
    ContErroresCom,
    numPaso:integer;
    xFechaHoraIni :string[10];
    xFechaHoraFin :string[10];
    xValores:array[1..10] of real;
    errorComunicacion:Boolean;
    rutaLog:string;
    estado:Integer;
    Token:string;
    licencia:string;
    lectRec:Boolean;
    function GetServiceController: TServiceController; override;
    procedure ProcesaLineaVeederRoot;
    procedure ComandoConsola(ss:string);
    function CalculoCrc(xstr:string):string;
    function CalcularCRC(Cmd: string): string;
    function CRC16(Data: AnsiString): AnsiString;
    function MD5(const usuario: string): string;
    function FechaHoraExtToStr(FechaHora:TDateTime):String;
    procedure AgregaLog(lin:string);
    procedure AgregaLogPetRes(lin: string);
    procedure ProcesaLinea2;  // EecoS
    procedure ProcesaLinea3;
    procedure ProcesaLinea6;  // INCON
    { Public declarations }
  end;


var
  ogcvtanques: Togcvtanques;
  key:OleVariant;
  claveCre,key3DES:string;

implementation

{$R *.DFM}

procedure ServiceController(CtrlCode: DWord); stdcall;
begin
  ogcvtanques.Controller(CtrlCode);
end;

function Togcvtanques.GetServiceController: TServiceController;
begin
  Result := ServiceController;
end;

procedure Togcvtanques.ServiceExecute(Sender: TService);
var
  config:TIniFile;
  lic:string;
begin
  try
    config:= TIniFile.Create(ExtractFilePath(ParamStr(0)) +'PTANQUES.ini');
    rutaLog:=config.ReadString('CONF','RutaLog','C:\ImagenCo');
    ServerSocket1.Port:=config.ReadInteger('CONF','Puerto',8484);
    licencia:=config.ReadString('CONF','Licencia','');
    ServerSocket1.Active:=True;
    estado:=-1;
    ListaLog:=TStringList.Create;
    ListaLogPetRes:=TStringList.Create;

    CoInitialize(nil);
    Key:=CreateOleObject('HaspDelphiAdapter.HaspAdapter');
    lic:=Key.GetKeyData(ExtractFilePath(ParamStr(0)),licencia);

    if UpperCase(ExtraeElemStrSep(lic,1,'|'))='FALSE' then begin
      ListaLog.Add('Error al validad licencia: '+ExtraeElemStrSep(lic,2,'|'));
      ListaLog.SaveToFile(rutaLog+'\LogTanqPetRes'+FiltraStrNum(FechaHoraToStr(Now))+'.txt');
      ServiceThread.Terminate;
      Exit;
    end
    else begin
      claveCre:=ExtraeElemStrSep(lic,2,'|');
      key3DES:=ExtraeElemStrSep(lic,3,'|');
    end;

    while not Terminated do
      ServiceThread.ProcessRequests(True);
    ServerSocket1.Active := False;
    CoUninitialize;
  except
    on e:Exception do begin
      ListaLog.Add('Error ServiceExecute: '+e.Message);
      ListaLog.SaveToFile(rutaLog+'\LogTanqPetRes'+FiltraStrNum(FechaHoraToStr(Now))+'.txt');
      ServiceThread.Terminate;
      Exit;
    end;
  end;
end;

procedure Togcvtanques.ServerSocket1ClientRead(Sender: TObject;
  Socket: TCustomWinSocket);
  var
    mensaje,comando,checksum:string;
    i:Integer;
    chks_invalido:Boolean;
begin
  try
    mensaje:=Key.Decrypt(ExtractFilePath(ParamStr(0)),key3DES,Socket.ReceiveText);
    AgregaLogPetRes('R '+mensaje);
    for i:=1 to Length(mensaje) do begin
      if mensaje[i]=#2 then begin
        mensaje:=Copy(mensaje,i+1,Length(mensaje));
        Break;
      end;
    end;
    for i:=Length(mensaje) downto 1 do begin
      if mensaje[i]=#3 then begin
        checksum:=Copy(mensaje,i+1,4);
        mensaje:=Copy(mensaje,1,i-1);
        Break;
      end;
    end;
    chks_invalido:=checksum<>CRC16(mensaje);
    if mensaje[1]='|' then
      Delete(mensaje,1,1);
    if mensaje[Length(mensaje)]='|' then
      Delete(mensaje,Length(mensaje),1);
    if NoElemStrSep(mensaje,'|')>=2 then begin
      if UpperCase(ExtraeElemStrSep(mensaje,1,'|'))<>'TANKS' then begin
        Responder(Socket,'TANKS|False|Este servicio solo procesa solicitudes de tanques|');
        Exit;
      end;

      comando:=UpperCase(ExtraeElemStrSep(mensaje,2,'|'));

      if chks_invalido then begin
        Responder(Socket,'TANKS|'+comando+'|False|Checksum invalido|');
        Exit;
      end;

      if comando='NOTHING' then
        Responder(Socket,'TANKS|NOTHING|True|')
      else if comando='INITIALIZE' then
        Responder(Socket,'TANKS|INITIALIZE|'+Inicializar(mensaje))
      else if comando='LOGIN' then
        Responder(Socket,'TANKS|LOGIN|'+Login(mensaje))
      else if comando='INVENTORY' then
        Responder(Socket,'TANKS|INVENTORY|'+InventarioTanques(mensaje))
      else if comando='TRACE' then
        Responder(Socket,'TANKS|TRACE|'+GuardarLog)
      else if comando='SAVELOGREQ' then
        Responder(Socket,'TANKS|SAVELOGREQ|'+GuardarLogPetRes)
      else if comando='LOG' then
        Socket.SendText(Key.Encrypt(ExtractFilePath(ParamStr(0)),key3DES,'TANKS|LOG|'+ObtenerLog(StrToIntDef(ExtraeElemStrSep(mensaje,3,'|'),0))))
      else if comando='LOGREQ' then
        Socket.SendText(Key.Encrypt(ExtractFilePath(ParamStr(0)),key3DES,'TANKS|LOGREQ|'+ObtenerLogPetRes(StrToIntDef(ExtraeElemStrSep(mensaje,3,'|'),0))))
      else if comando='CLEARLOG' then
        Responder(Socket,'TANKS|CLEARLOG|'+BorrarLog)
      else if comando='DELIVERIES' then
        Responder(Socket,'TANKS|DELIVERIES|'+EntradasTanques(StrToIntDef(ExtraeElemStrSep(mensaje,3,'|'),-1)))
      else if comando='HALT' then
        Responder(Socket,'TANKS|HALT|'+Detener)
      else if comando='RUN' then
        Responder(Socket,'TANKS|RUN|'+Iniciar)
      else if comando='STATE' then
        Responder(Socket,'TANKS|STATE|'+ObtenerEstado)
      else if comando='STATUS' then
        Responder(Socket,'TANKS|STATUS|True|[{"Categoria":"00","Tipo":"","Dispositivo":"","Descripcion":"All Functions Normal"}]|')
      else if comando='PARAMETERS' then
        Responder(Socket,'TANKS|PARAMETERS|True|')
      else if comando='SHUTDOWN' then
        Responder(Socket,'TANKS|SHUTDOWN|'+Shutdown)
      else if comando='TERMINATE' then
        Responder(Socket,'TANKS|TERMINATE|'+Terminar)
      else
        Responder(Socket,'TANKS|'+mensaje+'|False|Comando desconocido|');
    end
    else
      Responder(Socket,'TANKS|'+mensaje+'|False|Comando desconocido|');
  except
    on e:Exception do begin
      if (claveCre<>'') and (key3DES<>'') then
        AgregaLogPetRes('Error ServerSocket1ClientRead: '+e.Message+'//Clave CRE: '+claveCre+'//Terminacion de Key 3DES: '+copy(key3DES,Length(key3DES)-3,4))
      else
        AgregaLogPetRes('Error ServerSocket1ClientRead: '+e.Message);
      GuardarLogPetRes;
      Responder(Socket,'TANKS|'+comando+'|False|'+e.Message+'|');
    end;
  end;
end;

function Togcvtanques.InventarioTanques(mensaje:string): string;
var
  claveTanq,tanqueInt,i:Integer;
  root,tanque:TlkJSONobject;
  inventario:TlkJSONList;
begin
  if estado<1 then begin
    Result:='False|El proceso se encuentra detenido|';
    Exit;
  end;

  if errorComunicacion then begin
    Result:='False|Error de Comunicacion|';
    Exit;
  end;

  tanqueInt:=StrToIntDef(ExtraeElemStrSep(mensaje,3,'|'),-1);

  if tanqueInt<0 then begin
    Result:='False|La clave de tanque es incorrecta|';
    Exit;
  end;

  if (TM_Tanques.RecordCount>0) and (lectRec) then begin
    Result:='True|';
    claveTanq:=TM_TanquesCLAVE.AsInteger;
    root := TlkJSONobject.Create;
    inventario := TlkJSONList.Create;
    TM_Tanques.First;
    while not TM_Tanques.Eof do begin
      if (tanqueInt=0) or (tanqueInt=TM_TanquesCLAVE.AsInteger) then begin
        tanque:=TlkJSONobject.Create;
        tanque.Add('TankID',TM_TanquesCLAVE.AsInteger);
        tanque.Add('Active',True);
        tanque.Add('Volume',TM_TanquesVOLUMEN.AsFloat);
        tanque.Add('TCVolume',TM_TanquesVOLUMENTC.AsFloat);
        tanque.Add('Ullage',TM_TanquesPORLLENAR.AsFloat);
        tanque.Add('VolumeHeight',0);
        tanque.Add('WaterHeight',0);
        tanque.Add('Temperature',TM_TanquesTEMPERATURA.AsFloat);
        tanque.Add('WaterVolume',TM_TanquesVOLUMENAGUA.AsFloat);
        inventario.Add(tanque);
      end;
      TM_Tanques.Next;
    end;
    root.Add('Inventory',inventario);
    TM_Tanques.Locate('CLAVE',claveTanq,[]);
    i:=0;
    Result:='True|'+GenerateReadableText(root,i)+'|';
    root.Destroy;
  end
  else
    Result:='False|No se han inicializado los tanques|'
end;

procedure Togcvtanques.ComandoConsola(ss: string);
var s1:string;
begin
  inc(ContadorAlarma);
  inc(ContadorAlarma2);
  if tipoTanques<>6 then
    s1:=idSOH+ss
  else s1:=ss;
  if pSerial.OutBuffFree >= Length(S1) then begin
    AgregaLog('E '+s1);
    pSerial.PutString(s1);
  end;
end;

function Togcvtanques.IniciaPSerial(datosPuerto:string): string;
var
  puerto:string;
begin
  try
    if pSerial.Open then begin
      Result:='False|El puerto ya se encontraba abierto|';
      Exit;
    end;

    puerto:=ExtraeElemStrSep(datosPuerto,2,',');
    if Length(puerto)>=4 then begin
      if StrToIntDef(Copy(puerto,4,Length(puerto)-3),-99)=-99 then begin
        Result:='False|Favor de indicar un numero de puerto correcto|';
        Exit;
      end
      else
        pSerial.ComNumber:=StrToInt(Copy(puerto,4,Length(puerto)-3));
    end
    else begin
      if StrToIntDef(ExtraeElemStrSep(datosPuerto,2,','),-99)=-99 then begin
        Result:='False|Favor de indicar un numero de puerto correcto|';
        Exit;
      end
      else
        pSerial.ComNumber:=StrToInt(ExtraeElemStrSep(datosPuerto,2,','));
    end;

    if StrToIntDef(ExtraeElemStrSep(datosPuerto,3,','),-99)=-99 then begin
      Result:='False|Favor de indicar los baudios correctos|';
      Exit;
    end
    else
      pSerial.Baud:=StrToInt(ExtraeElemStrSep(datosPuerto,3,','));

    if ExtraeElemStrSep(datosPuerto,4,',')<>'' then begin
      case ExtraeElemStrSep(datosPuerto,4,',')[1] of
        'N':pSerial.Parity:=pNone;
        'E':pSerial.Parity:=pEven;
        'O':pSerial.Parity:=pOdd;
        else begin
          Result:='False|Favor de indicar una paridad correcta [N,E,O]|';
          Exit;
        end;
      end;
    end
    else begin
      Result:='False|Favor de indicar una paridad [N,E,O]|';
      Exit;
    end;

    if StrToIntDef(ExtraeElemStrSep(datosPuerto,5,','),-99)=-99 then begin
      Result:='False|Favor de indicar los bits de datos correctos|';
      Exit;
    end
    else
      pSerial.DataBits:=StrToInt(ExtraeElemStrSep(datosPuerto,5,','));

    if StrToIntDef(ExtraeElemStrSep(datosPuerto,6,','),-99)=-99 then begin
      Result:='False|Favor de indicar los bits de paro correctos|';
      Exit;
    end
    else
      pSerial.StopBits:=StrToInt(ExtraeElemStrSep(datosPuerto,6,','));
  except
    on e:Exception do
      Result:='False|Excepcion: '+e.Message+'|';
  end;
end;

function Togcvtanques.IniciaTanques(tanques: TlkJSONbase): string;
var
  i:Integer;
begin
  try

    if tanques.Count=0 then begin
      Result:='False|Favor de indicar los tanques activos|';
      Exit;
    end;

    TM_Tanques.Active:=True;
    TM_Entradas.Active:=True;

    if TM_Tanques.RecordCount>0 then begin
      TM_Tanques.EmptyTable;
      TM_Entradas.EmptyTable;
    end;

    for i:=0 to tanques.Count-1 do begin
      TM_Tanques.Append;
      TM_TanquesCLAVE.AsInteger:=tanques.Child[i].Field['TankId'].Value;;
      TM_Tanques.Post;
    end;
    TM_Tanques.First;
    lectRec:=False;
  except
    on e:Exception do begin
      TM_Tanques.Active:=False;
      Result:='False|Excepcion: '+e.Message+'|';
    end;
  end;
end;

function Togcvtanques.CalculoCrc(xstr: string): string;
var
   xCrc,xcomando:string;
   nCrc,nInt:word;
begin
  nInt:=15*16*16*16 + 15*16*16 + 15*16 + 15;  // 0xFFFF
  xcomando:='crc '+xstr+' '+inttostr(length(xstr))+' '+inttostr(nint);
  nCrc:=StrToInt(CalcularCRC(xcomando));
  xCrc:=IntToHex(nCrc,4);
  result:=xCrc;
end;

procedure Togcvtanques.Timer1Timer(Sender: TObject);
var
  ss,ss2:string;
begin
  if not pSerial.Open then
    Exit;

  errorComunicacion:=(ContadorAlarma>=10)or(ContadorAlarma2>=10);

  if (TM_Tanques.Eof) then
    TM_Tanques.First;

  if numPaso=1 then begin
    case TipoTanques of
      1:ComandoConsola('i201'+inttoclavenum(TM_TanquesCLAVE.AsInteger,2)); // VeederRoot
      2:ComandoConsola('E97'+inttostr(TM_TanquesCLAVE.AsInteger));  // EecoSystems
      3:ComandoConsola('10'+inttostr(TM_TanquesCLAVE.AsInteger));  // AutoStik
      4:ComandoConsola('i201'+inttoclavenum(TM_TanquesCLAVE.AsInteger,2)); // Red Jacket
      6:begin      // Incon
          ss:='18'+IntToClaveNum(TM_TanquesCLAVE.AsInteger,1)+'0';
          ss2:=CalculoCrc(ss);
          ss:=idSoh+ss+ss2+idEtx;
          ComandoConsola(ss);
        end;
    end;
  end
  else if numPaso=2 then begin
    case TipoTanques of
      1:begin  // VeederRoot
          ComandoConsola('i202'+inttoclavenum(TM_TanquesCLAVE.AsInteger,2));
          Sleep(2000);
        end;
      2:begin  // EecoSystems
          ComandoConsola('15'+inttostr(TM_TanquesCLAVE.AsInteger));
        end;
      3:begin  // AutoStik
          ComandoConsola('15'+inttostr(TM_TanquesCLAVE.AsInteger));
        end;
      4:begin  // Red Jacket
          ComandoConsola('i202'+inttoclavenum(TM_TanquesCLAVE.AsInteger,2));
          Sleep(2000);
        end;
      6:begin  // Incon
          ss:='1a'+inttoclavenum(TM_TanquesCLAVE.AsInteger,1)+'0';
          ss2:=CalculoCrc(ss);
          ss:=idSoh+ss+ss2+idEtx;
          ComandoConsola(ss);
        end;
    end;
  end;
end;

function CheckSumVeederRoot(Cadena:string):boolean;
var i,bin1,bin2:integer;
    ss1,ss2:string;
begin
  ss1:=copy(Cadena,1,length(Cadena)-4);
  ss2:=copy(Cadena,length(Cadena)-3,4);

  // Calcula cadena
  bin1:=1;
  for i:=1 to length(ss1) do
    bin1:=bin1+ord(ss1[i]);

  // Cacula checksum
  bin2:=BinaryToInt(HexLongToBinary(ss2));

  // calcula sumatoria
  result:=IntToBinary(bin1+bin2,16)='0000000000000000';
end;

procedure Togcvtanques.AgregaLog(lin: string);
var lin2:string;
    i:integer;
begin
  lin2:=FechaHoraExtToStr(now)+' ';
  for i:=1 to length(lin) do
    case lin[i] of
      #1:lin2:=lin2+'<SOH>';
      #2:lin2:=lin2+'<STX>';
      #3:lin2:=lin2+'<ETX>';
      #6:lin2:=lin2+'<ACK>';
      #21:lin2:=lin2+'<NAK>';
      #23:lin2:=lin2+'<ETB>';
      else lin2:=lin2+lin[i];
    end;
  while ListaLog.Count>10000 do
    ListaLog.Delete(0);
  ListaLog.Add(lin2);
end;

procedure Togcvtanques.AgregaLogPetRes(lin: string);
var lin2:string;
    i:integer;
begin
  lin2:=FechaHoraExtToStr(now)+' ';
  for i:=1 to length(lin) do
    case lin[i] of
      #1:lin2:=lin2+'<SOH>';
      #2:lin2:=lin2+'<STX>';
      #3:lin2:=lin2+'<ETX>';
      #6:lin2:=lin2+'<ACK>';
      #21:lin2:=lin2+'<NAK>';
      #23:lin2:=lin2+'<ETB>';
      else lin2:=lin2+lin[i];
    end;  
  while ListaLogPetRes.Count>10000 do
    ListaLogPetRes.Delete(0);
  ListaLogPetRes.Add(lin2);
end;

procedure Togcvtanques.ProcesaLineaVeederRoot;
var lin,line:string;
    xtan,xcant,xent,xval,xnum:integer;
    xFechaHoraI,
    xFechaHoraEnt:TDateTime;
begin
  try
    if LineaProc='' then
      exit;
    lin:=LineaProc;
    if (copy(Lin,1,4)='i201') then begin // INVANTARIO TANQUES
      xtan:=StrToIntDef(copy(lin,5,2),0);
      if TM_Tanques.Locate('CLAVE',xtan,[]) then begin
        lectRec:=true;
        TM_Tanques.Edit;
        TM_TanquesESTATUS.AsString:=copy(lin,20,4);
        TM_TanquesVOLUMEN.AsFloat:=IeeeToFloat(copy(lin,26,8));
        TM_TanquesVOLUMENTC.AsFloat:=IeeeToFloat(copy(lin,34,8));
        TM_TanquesVOLUMENAGUA.AsFloat:=IeeeToFloat(copy(lin,74,8));
        TM_TanquesPORLLENAR.AsFloat:=IeeeToFloat(copy(lin,42,8));
        TM_TanquesTEMPERATURA.AsFloat:=IeeeToFloat(copy(lin,66,8));
        TM_Tanques.Post;
        TM_Tanques.Next;
        if TM_Tanques.Eof then
          numPaso:=2;
      end;
    end
    else if copy(Lin,1,4)='i202' then begin // ENTRADAS AL TANQUES
      xtan:=StrToIntDef(copy(lin,5,2),0);
      if TM_Tanques.Locate('CLAVE',xtan,[]) then begin
        TM_Entradas.First;
        while not TM_Entradas.Eof do begin
          if TM_EntradasTANQUE.AsInteger=xtan then
            TM_Entradas.Delete;
          TM_Entradas.Next;
        end;
        xCant:=StrToInt(copy(lin,20,2));
        delete(lin,1,21);
        for xent:=1 to xCant do begin
          line:=copy(lin,1,102);
          xfechahoraini:=copy(line,1,10);
          xfechahorafin:=copy(line,11,10);
          xnum:=hextoint(copy(line,21,2));
          xFechaHoraI:=StrToFechaHora('20'+xfechahoraini);
          xFechaHoraEnt:=StrToFechaHora('20'+xfechahorafin);
          if abs(xfechahoraent-xfechahorai)<2 then begin
            delete(line,1,22);
            for xval:=1 to 8 do begin
              if (length(line)>=8) then begin
                xvalores[xval]:=IeeeToFloat(copy(line,1,8));
                delete(line,1,8);
              end
              else xvalores[xval]:=0;
            end;
            TM_Entradas.Append;
            TM_EntradasTANQUE.AsInteger:=xtan;
            TM_EntradasVOLUMENININETO.AsFloat:=AjustaFloat(xValores[2],3);
            TM_EntradasVOLUMENFINNETO.AsFloat:=AjustaFloat(xValores[6],3);
            TM_EntradasVOLUMENINIBRUTO.AsFloat:=AjustaFloat(xValores[1],3);
            TM_EntradasVOLUMENFINBRUTO.AsFloat:=AjustaFloat(xValores[5],3);
            TM_EntradasTEMPERATURA.AsFloat:=AjustaFloat(xValores[8],3);
            TM_EntradasFECHAHORAINI.AsDateTime:=StrToFechaHora('20'+xFechaHoraIni);
            TM_EntradasFECHAHORAFIN.AsDateTime:=StrToFechaHora('20'+xFechaHoraFin);
            TM_Entradas.Post;
          end;
          delete(lin,1,22+xnum*8);
        end;
        TM_Tanques.Next;
        if TM_Tanques.Eof then begin
          numPaso:=1;
          Timer1.Enabled:=False;
          Timer1.Enabled:=True;
        end;
      end;
    end;
  except
  end;
end;

function Togcvtanques.CalcularCRC(Cmd: string): string;
var
  Buffer: array[0..4096] of Char;
  si: STARTUPINFO;
  sa: SECURITY_ATTRIBUTES;
  sd: SECURITY_DESCRIPTOR;
  pi: PROCESS_INFORMATION;
  newstdin, newstdout, read_stdout, write_stdin: THandle;
  exitcod, bread, avail: Cardinal;

  function IsWinNT: boolean;
  var
    OSV: OSVERSIONINFO;
  begin
    OSV.dwOSVersionInfoSize := sizeof(osv);
    GetVersionEx(OSV);
    result := OSV.dwPlatformId = VER_PLATFORM_WIN32_NT;
  end;

begin
  Result:= '';
  if IsWinNT then
  begin
    InitializeSecurityDescriptor(@sd, SECURITY_DESCRIPTOR_REVISION);
    SetSecurityDescriptorDacl(@sd, true, nil, false);
    sa.lpSecurityDescriptor := @sd;
  end
  else sa.lpSecurityDescriptor := nil;
  sa.nLength := sizeof(SECURITY_ATTRIBUTES);
  sa.bInheritHandle := TRUE;
  if CreatePipe(newstdin, write_stdin, @sa, 0) then
  begin
    if CreatePipe(read_stdout, newstdout, @sa, 0) then
    begin
      GetStartupInfo(si);
      with si do
      begin
        dwFlags := STARTF_USESTDHANDLES or STARTF_USESHOWWINDOW;
        wShowWindow := SW_HIDE;
        hStdOutput := newstdout;
        hStdError := newstdout;
        hStdInput := newstdin;
      end;
      Fillchar(Buffer, SizeOf(Buffer), 0);
      GetEnvironmentVariable('COMSPEC', @Buffer, SizeOf(Buffer) - 1);
      StrCat(@Buffer,PChar(' /c ' + Cmd));
      if CreateProcess(nil, @Buffer, nil, nil, TRUE, CREATE_NEW_CONSOLE, nil, nil, si, pi) then
      begin
        repeat
          PeekNamedPipe(read_stdout, @Buffer, SizeOf(Buffer) - 1, @bread, @avail, nil);
          if bread > 0 then
          begin
            Fillchar(Buffer, SizeOf(Buffer), 0);
            ReadFile(read_stdout, Buffer, bread, bread, nil);
            Result:= Result + String(PChar(@Buffer));
          end;
          GetExitCodeProcess(pi.hProcess, exitcod);
        until (exitcod <> STILL_ACTIVE) and (bread = 0);
      end;
      CloseHandle(read_stdout);
      CloseHandle(newstdout);
    end;
    CloseHandle(newstdin);
    CloseHandle(write_stdin);
  end;
end;

function Togcvtanques.FechaHoraExtToStr(FechaHora: TDateTime): String;
begin
  result:=FechaPaq(FechaHora)+' '+FormatDatetime('hh:mm:ss.zzz',FechaHora);
end;

procedure Togcvtanques.ProcesaLinea2;
var lin,line:string;
    xtan,xcant,xent:integer;
    xFechaHoraEnt:TDateTime;
begin
  try
    if LineaProc='' then
      exit;
    lin:=LineaProc;
    if (copy(Lin,1,3)='E97') then begin // INVANTARIO TANQUES
      lectRec:=true;
      xtan:=StrToIntDef(copy(lin,4,1),0);
      if xtan=TM_TanquesCLAVE.AsInteger then begin
        TM_Tanques.Edit;
        TM_TanquesVOLUMEN.AsFloat:=StrToFloat(limpiastr(copy(lin,17,12)));
        TM_TanquesVOLUMENAGUA.AsFloat:=StrToFloat(limpiastr(copy(lin,65,12)));
        TM_TanquesPORLLENAR.AsFloat:=StrToFloat(limpiastr(copy(lin,53,12)));
        TM_TanquesTEMPERATURA.AsFloat:=StrToFloat(limpiastr(copy(lin,41,12)));
        TM_Tanques.Post;
        TM_Tanques.Next;
        if TM_Tanques.Eof then
          numPaso:=2;
      end;
    end
    else if copy(Lin,1,2)='15' then begin // ENTRADAS AL TANQUES
      xtan:=StrToIntDef(copy(lin,3,1),0);
      if TM_Tanques.Locate('CLAVE',xtan,[]) then begin
        TM_Entradas.First;
        while not TM_Entradas.Eof do begin
          if TM_EntradasTANQUE.AsInteger=xtan then
            TM_Entradas.Delete;
          TM_Entradas.Next;
        end;
        xCant:=StrToInt(copy(lin,6,2));
        delete(lin,1,7);
        for xent:=1 to xCant do begin
          line:=copy(lin,1,38);
          xfechahoraini:=IntToClaveNum(GetAnoFromFecha(date),2)+copy(line,1,8);
          xfechahorafin:=IntToClaveNum(GetAnoFromFecha(date),2)+copy(line,20,8);
          xFechaHoraEnt:=StrToFechaHora('20'+xfechahorafin);
          if xFechaHoraEnt>(date+1) then begin
            xfechahoraini:=IntToClaveNum(GetAnoFromFecha(date)-1,2)+copy(line,1,8);
            xfechahorafin:=IntToClaveNum(GetAnoFromFecha(date)-1,2)+copy(line,20,8);
          end;
          TM_Entradas.Append;
          TM_EntradasTANQUE.AsInteger:=xtan;
          TM_EntradasVOLUMENININETO.AsFloat:=StrToFloat(copy(lin,9,6));
          TM_EntradasVOLUMENFINNETO.AsFloat:=StrToFloat(copy(lin,28,6));
          TM_EntradasTEMPERATURA.AsFloat:=StrToFloat(copy(lin,34,5))/10;
          TM_EntradasFECHAHORAINI.AsDateTime:=StrToFechaHora('20'+xFechaHoraIni);
          TM_EntradasFECHAHORAFIN.AsDateTime:=StrToFechaHora('20'+xFechaHoraFin);
          TM_Entradas.Post;
          delete(lin,1,38);
        end;
        TM_Tanques.Next;
        if TM_Tanques.Eof then
          numPaso:=1;
      end;
    end;
  except
    on e:Exception do
      AgregaLog('Error ProcesaLinea2: '+e.Message);
  end;
end;

procedure Togcvtanques.ProcesaLinea3;
var lin,line:string;
    xtan,xcant,xent,i:integer;
    xFechaHoraEnt:TDateTime;
begin
  try
    if LineaProc='' then
      exit;
    lin:=LineaProc;
    if (copy(Lin,1,2)='10') then begin // INVANTARIO TANQUES
      lectRec:=true;
      xtan:=StrToIntDef(copy(lin,3,1),0);
      if xtan=TM_TanquesCLAVE.AsInteger then begin
        TM_Tanques.Edit;
        TM_TanquesVOLUMEN.AsFloat:=StrToFloat(limpiastr(copy(lin,26,6)));
        TM_TanquesPORLLENAR.AsFloat:=StrToFloat(limpiastr(copy(lin,37,6)));
        TM_TanquesTEMPERATURA.AsFloat:=StrToFloat(limpiastr(copy(lin,33,4)))/100;
        TM_Tanques.Post;
        TM_Tanques.Next;
        if TM_Tanques.Eof then
          numPaso:=2;
      end;
    end
    else if copy(Lin,1,2)='15' then begin // ENTRADAS AL TANQUES
      xtan:=StrToIntDef(copy(lin,3,1),0);
      if TM_Tanques.Locate('CLAVE',xtan,[]) then begin
        TM_Entradas.First;
        while not TM_Entradas.Eof do begin
          if TM_EntradasTANQUE.AsInteger=xtan then
            TM_Entradas.Delete;
          TM_Entradas.Next;
        end;
        xCant:=StrToInt(copy(lin,6,2));
        delete(lin,1,7);
        for xent:=1 to xCant do begin
          line:=copy(lin,1,38);
          for i:=1 to 8 do if not(line[i] in ['0'..'9']) then
            line[i]:='0';
          for i:=20 to 27 do if not(line[i] in ['0'..'9']) then
            line[i]:='0';
          xfechahoraini:=IntToClaveNum(GetAnoFromFecha(date),2)+copy(line,1,8);
          xfechahorafin:=IntToClaveNum(GetAnoFromFecha(date),2)+copy(line,20,8);
          xFechaHoraEnt:=StrToFechaHora('20'+xfechahorafin);
          if xFechaHoraEnt>(date+1) then begin
            xfechahoraini:=IntToClaveNum(GetAnoFromFecha(date)-1,2)+copy(line,1,8);
            xfechahorafin:=IntToClaveNum(GetAnoFromFecha(date)-1,2)+copy(line,20,8);
          end;
          TM_Entradas.Append;
          TM_EntradasTANQUE.AsInteger:=xtan;
          TM_EntradasVOLUMENININETO.AsFloat:=StrToFloat(copy(lin,9,6));
          TM_EntradasVOLUMENFINNETO.AsFloat:=StrToFloat(copy(lin,28,6));
          TM_EntradasTEMPERATURA.AsFloat:=StrToFloat(copy(lin,35,4))/100;
          TM_EntradasFECHAHORAINI.AsDateTime:=StrToFechaHora('20'+xFechaHoraIni);
          TM_EntradasFECHAHORAFIN.AsDateTime:=StrToFechaHora('20'+xFechaHoraFin);
          TM_Entradas.Post;
          delete(lin,1,38);
        end;
        TM_Tanques.Next;
        if TM_Tanques.Eof then
          numPaso:=1;
      end;
    end;
  except
  end;
end;

procedure Togcvtanques.pSerialTriggerAvail(CP: TObject; Count: Word);
var I:Word;
    C:Char;
begin
  SwTimer1:=false;
  try
    ContadorAlarma:=0;
    try
      case TipoTanques of
        1:begin // VeederRoot
            for I := 1 to Count do begin
              C:=pSerial.GetChar;
              case c of
                idSOH:begin
                        LineaBuff:='';
                      end;
                idETX:begin
                        LineaProc:=LineaBuff; // 815 7562 X 566833
                        if CheckSumVeederRoot(LineaProc) then begin
                          ContadorAlarma2:=0;
                          AgregaLog('R '+LineaProc);
                          ContRec:=0;
                          ProcesaLineaVeederRoot;
                        end
                        else begin
                          inc(conterrorescom);
                          AgregaLog('Errores de Comunicacion: '+inttostr(conterrorescom));
                        end;
                      end;
                else LineaBuff:=LineaBuff+C;
              end;
            end;
          end;
        2:begin // EecoSystems
            for I := 1 to Count do begin
              C:=pSerial.GetChar;
              case c of
                idSOH:begin
                        LineaBuff:='';
                      end;
                idETX:begin
                        LineaProc:=LineaBuff;
                        ContadorAlarma2:=0;
                        AgregaLog('R '+LineaProc);
                        ContRec:=0;
                        ProcesaLinea2;
                      end;
                else LineaBuff:=LineaBuff+C;
              end;
            end;
          end;
        3:begin // AutoStik
            for I := 1 to Count do begin
              C:=pSerial.GetChar;
              case c of
                idSOH:begin
                        LineaBuff:='';
                      end;
                idETX:begin
                        LineaProc:=LineaBuff;
                        ContadorAlarma2:=0;
                        AgregaLog('R '+LineaProc);
                        if (copy(Lineaproc,1,2)='10') then begin
                          if (copy(lineaproc,46,1)='9') then begin
                            ContRec:=0;
                            ContadorAlarma3:=0;
                            ProcesaLinea3;
                          end
                          else inc(ContadorAlarma3);
                        end
                        else begin
                          ContRec:=0;
                          ProcesaLinea3;
                        end;
                      end;
                else LineaBuff:=LineaBuff+C;
              end;
            end;
          end;
        4:begin // Red Jacket
            for I := 1 to Count do begin
              C:=pSerial.GetChar;
              case c of
                idSOH:begin
                        LineaBuff:='';
                      end;
                idETX:begin
                        LineaProc:=LineaBuff; // 815 7562 X 566833
                        if CheckSumVeederRoot(LineaProc) then begin
                          ContadorAlarma2:=0;
                          AgregaLog('R '+LineaProc);
                          ContRec:=0;
                          ProcesaLineaVeederRoot;
                        end
                        else begin
                          inc(conterrorescom);
                          AgregaLog('Errores de Comunicacion: '+inttostr(conterrorescom));
                        end;
                      end;
                else LineaBuff:=LineaBuff+C;
              end;
            end;
          end;
        6:begin // INCON
            for I := 1 to Count do begin
              C:=pSerial.GetChar;
              case c of
                idSOH:begin
                        LineaBuff:='';
                      end;
                idETX:begin
                        LineaProc:=LineaBuff; // 815 7562 X 566833
                        if true then begin //CheckSumVeederRoot(LineaProc) then begin
                          ContadorAlarma2:=0;
                          AgregaLog('R '+LineaProc);
                          ContRec:=0;
                          ProcesaLinea6;
                        end
                        else begin
                          inc(conterrorescom);
                          AgregaLog('Errores de Comunicacion: '+inttostr(conterrorescom));
                        end;
                      end;
                else LineaBuff:=LineaBuff+C;
              end;
            end;
          end;
      end;
    except
      on e:Exception do begin
        SwTimer1:=true;
        AgregaLog('Excepcion pSerialTriggerAvail: '+e.Message);
      end;
    end;
  finally
    SwTimer1:=true;
  end;
end;

procedure Togcvtanques.ProcesaLinea6;
var lin,line:string;
    xtan,xcant,xent:integer;
    xFechaHoraI,
    xFechaHoraEnt:TDateTime;
  function StrToFloatIncon(xstr:string):double;
  begin
    if xstr[2]='.' then
      insert('0',xstr,2);
    try
      result:=StrToFloat(xstr);
    except
      result:=0;
    end;
  end;
begin
  try
    if LineaProc='' then
      exit;
    lin:=LineaProc;
    if (copy(Lin,1,2)='18') then begin // INVANTARIO TANQUES
      lectRec:=true;
      xtan:=StrToIntDef(copy(lin,3,1),0);
      if xtan=TM_TanquesCLAVE.AsInteger then begin
        line:=copy(lin,21,8);
        TM_Tanques.Edit;
        TM_TanquesVOLUMEN.AsFloat:=StrToFloatIncon(copy(lin,21,8));
        TM_TanquesVOLUMENAGUA.AsFloat:=StrToFloatIncon(copy(lin,29,8));
        TM_TanquesPORLLENAR.AsFloat:=StrToFloatIncon(copy(lin,37,8));
        TM_TanquesTEMPERATURA.AsFloat:=StrToFloatIncon(copy(lin,53,8));
        TM_Tanques.Post;
        TM_Tanques.Next;
        if TM_Tanques.Eof then
          numPaso:=2;        
      end;
    end
    else if copy(Lin,1,2)='1a' then begin // ENTRADAS AL TANQUES
      xtan:=StrToIntDef(copy(lin,3,1),0);
      if TM_Tanques.Locate('CLAVE',xtan,[]) then begin
        TM_Entradas.First;
        while not TM_Entradas.Eof do begin
          if TM_EntradasTANQUE.AsInteger=xtan then
            TM_Entradas.Delete;
          TM_Entradas.Next;
        end;
        xCant:=1;
        for xent:=1 to xCant do begin
          xfechahoraini:=copy(lin,13,6)+copy(lin,9,2)+copy(lin,7,2);
          xfechahorafin:=copy(lin,76,6)+copy(lin,72,2)+copy(lin,70,2);
          xFechaHoraI:=StrToFechaHora('20'+xfechahoraini);
          xFechaHoraEnt:=StrToFechaHora('20'+xfechahorafin);
          if abs(xfechahoraent-xfechahorai)<2 then begin
            TM_Entradas.Append;
            TM_EntradasTANQUE.AsInteger:=xtan;
            TM_EntradasVOLUMENININETO.AsFloat:=StrToFloatIncon(copy(lin,20,8));
            TM_EntradasVOLUMENFINNETO.AsFloat:=StrToFloatIncon(copy(lin,83,8));
            TM_EntradasTEMPERATURA.AsFloat:=StrToFloatIncon(copy(lin,83,8));
            TM_EntradasFECHAHORAINI.AsDateTime:=StrToFechaHora('20'+xFechaHoraIni);
            TM_EntradasFECHAHORAFIN.AsDateTime:=StrToFechaHora('20'+xFechaHoraFin);
            TM_Entradas.Post;
          end;
        end;
        TM_Tanques.Next;
        if TM_Tanques.Eof then
          numPaso:=1;
      end;
    end;
  except
  end;
end;

function Togcvtanques.GuardarLog:string;
begin
  try
    ListaLog.SaveToFile(rutaLog+'\LogTanques'+FiltraStrNum(FechaHoraToStr(Now))+'.txt');
    GuardarLogPetRes;
    Result:='True|'+rutaLog+'\LogTanq'+FiltraStrNum(FechaHoraToStr(Now))+'.txt';
  except
    on e:Exception do
      Result:='False|Excepcion: '+e.Message+'|';
  end;
end;

function Togcvtanques.GuardarLogPetRes:string;
begin
  try
    ListaLogPetRes.SaveToFile(rutaLog+'\LogTanqPetRes'+FiltraStrNum(FechaHoraToStr(Now))+'.txt');
    Result:='True|';
  except
    on e:Exception do
      Result:='False|Excepcion: '+e.Message+'|';
  end;
end;

function Togcvtanques.BorrarLog: string;
begin
  try
    ListaLog.Clear;
    Result:='True|';
  except
    on e:Exception do
      Result:='False|Excepcion: '+e.Message+'|';
  end;  
end;

function Togcvtanques.EntradasTanques(tanque:Integer): string;
var
  entrada:TlkJSONobject;
  entradas:TlkJSONList;
  i:Integer;
begin
  if estado<1 then begin
    Result:='False|El proceso se encuentra detenido|';
    Exit;
  end;

  if errorComunicacion then begin
    Result:='False|Error de Comunicacion|';
    Exit;
  end;
  
  if tanque<0 then begin
    Result:='False|Favor de indicar el numero de tanque|';
    Exit;
  end;

  if TM_Entradas.RecordCount>0 then begin
    entradas := TlkJSONList.Create;
    TM_Entradas.First;
    while not TM_Entradas.Eof do begin
      if (TM_EntradasTANQUE.AsInteger=tanque) or (tanque=0) then begin
        entrada:=TlkJSONobject.Create;
        entrada.Add('TankId',TM_EntradasTANQUE.AsInteger);
        entrada.Add('StartingDateTime',FormatDateTime('yyyy-mm-dd',TM_EntradasFECHAHORAINI.AsDateTime)+'T'+FormatDateTime('hh:nn:ss.zzz',TM_EntradasFECHAHORAINI.AsDateTime)+'Z');
        entrada.Add('StartingVolume',TM_EntradasVOLUMENINIBRUTO.AsFloat);
        entrada.Add('StartingTCVolume',TM_EntradasVOLUMENININETO.AsFloat);
        entrada.Add('StartingWater',0);
        entrada.Add('StartingTemperature',TM_EntradasTEMPERATURA.AsFloat);
        entrada.Add('StartingHeight',0);
        entrada.Add('EndingDateTime',FormatDateTime('yyyy-mm-dd',TM_EntradasFECHAHORAFIN.AsDateTime)+'T'+FormatDateTime('hh:nn:ss.zzz',TM_EntradasFECHAHORAFIN.AsDateTime)+'Z');
        entrada.Add('EndingVolume',TM_EntradasVOLUMENFINBRUTO.AsFloat);
        entrada.Add('EndingTCVolume',TM_EntradasVOLUMENFINNETO.AsFloat);
        entrada.Add('EndingWater',0);
        entrada.Add('EndingTemperature',TM_EntradasTEMPERATURA.AsFloat);
        entrada.Add('EndingHeight',0);

        entradas.Add(entrada);
      end;
      TM_Entradas.Next;
    end;
    if entradas.Count=0 then begin
      Result:='False|No se encontraron entradas de tanque|';
      Exit;
    end;
    i:=0;
    Result:='True|'+GenerateReadableText(entradas,i)+'|';
    entradas.Destroy;
  end
  else if TM_Tanques.RecordCount=0 then
    Result:='False|No se han inicializado los tanques|'
  else
    Result:='False|No hay registro de entradas|';
end;

function Togcvtanques.Detener: string;
begin
  try
    if estado=-1 then begin
      Result:='False|El proceso no se ha iniciado aun|';
      Exit;
    end;

    if estado=1 then begin
      pSerial.Open:=False;
      Timer1.Enabled:=False;
      estado:=0;
      Result:='True|';
    end
    else
      Result:='False|El proceso ya habia sido detenido|'
  except
    on e:Exception do
      Result:='False|'+e.Message+'|';
  end;  
end;

procedure Togcvtanques.Responder(socket:TCustomWinSocket;resp:string);
begin
  socket.SendText(Key.Encrypt(ExtractFilePath(ParamStr(0)),key3DES,#1#2+resp+#3+CRC16(resp)+#23));
  AgregaLogPetRes('E '+#1#2+resp+#3+CRC16(resp)+#23);
end;

function Togcvtanques.ObtenerLog(r: Integer): string;
var
  i:Integer;
begin
  if r=0 then begin
    Result:='False|No se indico el numero de registros|';
    Exit;
  end;

  if ListaLog.Count<1 then begin
    Result:='False|No hay registros en el log|';
    Exit;
  end;

  i:=ListaLog.Count-(r+1);
  if i<1 then i:=0;

  Result:='True|';

  for i:=i to ListaLog.Count-1 do
    Result:=Result+ListaLog[i]+'|';
end;

function Togcvtanques.ObtenerLogPetRes(r: Integer): string;
var
  i:Integer;
begin
  if r=0 then begin
    Result:='False|No se indico el numero de registros|';
    Exit;
  end;

  if ListaLogPetRes.Count<1 then begin
    Result:='False|No hay registros en el log de peticiones|';
    Exit;
  end;

  i:=ListaLogPetRes.Count-(r+1);
  if i<1 then i:=0;

  Result:='True|';

  for i:=i to ListaLogPetRes.Count-1 do
    Result:=Result+ListaLogPetRes[i]+'|';
end;

function Togcvtanques.Iniciar: string;
begin
  try
    if estado=1 then begin
      Result:='False|El proceso ya se encuentra en ejecucion|';
      Exit;
    end;

    if (estado=-1) then begin
      Result:='False|No se ha inicializado el puerto serial|';
      Exit;
    end
    else if not pSerial.Open then
      pSerial.Open:=True;

    if TM_Tanques.RecordCount=0 then begin
      Result:='False|No se han inicializado los tanques|';
      Exit;
    end; 

    Result:='True|';
    estado:=1;
    Timer1.Enabled:=True;
    numPaso:=1;
  except
    on e:Exception do
      Result:='False|'+e.Message+'|';
  end;
end;

function Togcvtanques.ObtenerEstado: string;
begin
  Result:='True|'+IntToStr(estado)+'|';
end;

function Togcvtanques.CRC16(Data: AnsiString): AnsiString;
var
  aCrc:TCRC;
  pin : Pointer;
  insize:Cardinal;
begin
  insize:=Length(Data);
  pin:=@Data[1];
  aCrc:=TCRC.Create(CRC16Desc);
  aCrc.CalcBlock(pin,insize);
  Result:=IntToHex(aCrc.Finish,4);
  aCrc.Destroy;
end;

function Togcvtanques.Inicializar(json: string): string;
var 
  js: TlkJSONBase;
  consolas,tanques: TlkJSONbase;
  datosPuerto,marcaTanques:string;
begin
  try
    if estado>-1 then begin
      Result:='False|El servicio ya habia sido inicializado.|';
      Exit;
    end;

    js := TlkJSON.ParseText(ExtraeElemStrSep(json,3,'|'));
    consolas := js.Field['Consoles'];

    marcaTanques:=UpperCase(VarToStr(consolas.Child[0].Field['Protocol'].Value));

    if marcaTanques='VEEDER ROOT' then
      tipoTanques:=1
    else if marcaTanques='EECOSYSTEM' then
      tipoTanques:=2
    else if marcaTanques='AUTOSTICK' then
      tipoTanques:=3
    else if marcaTanques='REDJACKET' then
      tipoTanques:=4
    else if marcaTanques='INCON' then
      tipoTanques:=6;

    datosPuerto:=VarToStr(consolas.Child[0].Field['Connection'].Value);

    Result:=IniciaPSerial(datosPuerto);

    if Result<>'' then
      Exit;

    tanques := js.Field['Tanks'];

    Result:=IniciaTanques(tanques);

    tanques.Free;

    if Result<>'' then
      Exit;

    estado:=0;
    Result:='True|';
  except
    on e:Exception do
      Result:='False|Excepcion: '+e.Message+'|';
  end;
end;

function Togcvtanques.Shutdown: string;
begin
  if estado>0 then
    Result:='False|El servicio esta en proceso, no fue posible detenerlo|'
  else begin
    ServiceThread.Terminate;
    Result:='True|';
  end;
end;

function Togcvtanques.Terminar: string;
begin
  Timer1.Enabled:=False;
  pSerial.Open:=False;
  TM_Tanques.EmptyTable;
  TM_Entradas.EmptyTable;
  estado:=-1;
  Result:='True|';
end;

function Togcvtanques.Login(mensaje: string): string;
var
  usuario,password:string;
begin
  usuario:=ExtraeElemStrSep(mensaje,3,'|');
  password:=ExtraeElemStrSep(mensaje,4,'|');
  if MD5(usuario+'|'+FormatDateTime('yyyy-mm-dd',Date)+'T'+FormatDateTime('hh:nn',Now))<>password then
    Result:='False|Password invalido|'
  else begin
    Token:=MD5(usuario+'|'+FormatDateTime('yyyy-mm-dd',Date)+'T'+FormatDateTime('hh:nn',Now));
    Result:='True|';
  end;
end;

function Togcvtanques.MD5(const usuario: string): string;
var
  idmd5:TIdHashMessageDigest5;
  hash:T4x4LongWordRecord;
begin
  idmd5 := TIdHashMessageDigest5.Create;
  hash := idmd5.HashValue(usuario);
  Result := idmd5.AsHex(hash);
  Result := AnsiLowerCase(Result);
  idmd5.Destroy;
end;

procedure Togcvtanques.Timer2Timer(Sender: TObject);
begin
  if not ServerSocket1.Active then begin
    ServerSocket1.Active:=True;
    AgregaLog('Se reinicio socket');
    GuardarLog;
  end;
end;

end.

unit UCLIENTE;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ScktComp, StdCtrls, AdvToolBar, CRCs, OG_Hasp, ActiveX, ComObj,
  LbCipher, LbString;

type
  TForm1 = class(TForm)
    Button1: TButton;
    ListBox1: TListBox;
    ClientSocket1: TClientSocket;
    Button2: TButton;
    Button3: TButton;
    ComboBox1: TComboBox;
    Edit2: TEdit;
    ComboBox2: TComboBox;
    CheckBox1: TCheckBox;
    Edit1: TEdit;
    Label1: TLabel;
    procedure Button1Click(Sender: TObject);
    procedure ClientSocket1Read(Sender: TObject; Socket: TCustomWinSocket);
    procedure ClientSocket1Connect(Sender: TObject;
      Socket: TCustomWinSocket);
    procedure ClientSocket1Disconnect(Sender: TObject;
      Socket: TCustomWinSocket);
    procedure Edit1KeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure ComboBox1Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
    conectado:Boolean;

  public
    { Public declarations }
   Key: OleVariant;
   claveCre,key3DES:string;
   function CRC16(Data: AnsiString): AnsiString;
   function Encrypt(data,key3DES:string):string;
   function Decrypt(data,key3DES:string):string;

  end;

var
  Form1: TForm1;
  VendorCode : AnsiString =
    'AzIceaqfA1hX5wS+M8cGnYh5ceevUnOZIzJBbXFD6dgf3tBkb9cvUF/Tkd/iKu2fsg9wAysYKw7RMA' +
    'sVvIp4KcXle/v1RaXrLVnNBJ2H2DmrbUMOZbQUFXe698qmJsqNpLXRA367xpZ54i8kC5DTXwDhfxWT' +
    'OZrBrh5sRKHcoVLumztIQjgWh37AzmSd1bLOfUGI0xjAL9zJWO3fRaeB0NS2KlmoKaVT5Y04zZEc06' +
    'waU2r6AU2Dc4uipJqJmObqKM+tfNKAS0rZr5IudRiC7pUwnmtaHRe5fgSI8M7yvypvm+13Wm4Gwd4V' +
    'nYiZvSxf8ImN3ZOG9wEzfyMIlH2+rKPUVHI+igsqla0Wd9m7ZUR9vFotj1uYV0OzG7hX0+huN2E/Id' +
    'gLDjbiapj1e2fKHrMmGFaIvI6xzzJIQJF9GiRZ7+0jNFLKSyzX/K3JAyFrIPObfwM+y+zAgE1sWcZ1' +
    'YnuBhICyRHBhaJDKIZL8MywrEfB2yF+R3k9wFG1oN48gSLyfrfEKuB/qgNp+BeTruWUk0AwRE9XVMU' +
    'uRbjpxa4YA67SKunFEgFGgUfHBeHJTivvUl0u4Dki1UKAT973P+nXy2O0u239If/kRpNUVhMg8kpk7' +
    's8i6Arp7l/705/bLCx4kN5hHHSXIqkiG9tHdeNV8VYo5+72hgaCx3/uVoVLmtvxbOIvo120uTJbuLV' +
    'TvT8KtsOlb3DxwUrwLzaEMoAQAFk6Q9bNipHxfkRQER4kR7IYTMzSoW5mxh3H9O8Ge5BqVeYMEW36q' +
    '9wnOYfxOLNw6yQMf8f9sJN4KhZty02xm707S7VEfJJ1KNq7b5pP/3RjE0IKtB2gE6vAPRvRLzEohu0' +
    'm7q1aUp8wAvSiqjZy7FLaTtLEApXYvLvz6PEJdj4TegCZugj7c8bIOEqLXmloZ6EgVnjQ7/ttys7VF' +
    'ITB3mazzFiyQuKf4J6+b/a/Y';

implementation

uses
  ULIBGRAL;

{$R *.dfm}

procedure TForm1.Button1Click(Sender: TObject);
var
  i:Integer;
  json,jsonT,jsonP,mensaje,lic:string;
begin
  try
    CoInitialize(nil);
    Key:=CreateOleObject('HaspDelphiAdapter.HaspAdapter');
    lic:=Key.GetKeyData(ExtractFilePath(ParamStr(0)),Edit1.Text);
    if UpperCase(ExtraeElemStrSep(lic,1,'|'))='FALSE' then
      MensajeErr('Error al validar licencia')
    else begin
      claveCre:=ExtraeElemStrSep(lic,2,'|');
      key3DES:=ExtraeElemStrSep(lic,3,'|');
      key:=Unassigned;
    end;

    Button1.Enabled:=False;
    ClientSocket1.Host:=ExtraeElemStrSep(Edit2.Text,1,':');
    ClientSocket1.Port:=StrToInt(ExtraeElemStrSep(Edit2.Text,2,':'));
    ClientSocket1.Active:=True;
    for i:=0 to 100 do begin
      Sleep(10);
      Application.ProcessMessages;
      if conectado then Break;
    end;
    if conectado then begin
//      json:= '|DISPENSERS|INITIALIZE|{"Consoles":[{"ConsoleId":1,"Connection":"SERIAL,COM5,9600,E,7,1","'+
//             'Protocol":"PAM","LastDispenser":1},{"ConsoleId":2,"Connection":"IP,192.168.1.50,3112","Protocol":"HYPERPIB","'+
//             'LastDispenser":1}],"Products":[{"ProductId":1,"Name":"REGULAR","Price":20},{"ProductId":2,"Name":"PREMIUM"'+
//             ',"Price":21},{"ProductId":3,"Name":"DIESEL","Price":22}],"Dispensers":[{"DispenserId":1,"MaximumSale":9999,"U'+
//             'nits":"MONEY","OperationMode":"FULLSERVICE","Blocked":true,"Hoses":[{"HoseId":1,"ProductId":3},{"HoseId":2'+
//             ',"ProductId":1},{"HoseId":3,"ProductId":2}]},{"DispenserId":2,"MaximumSale":999,"Units":"VOLUME","OperationM'+
//             'ode":"FULLSERVICE","Blocked":false,"Hoses":[{"HoseId":1,"ProductId":3},{"HoseId":2,"ProductId":1},{"HoseId":3,'+
//             '"ProductId":2}]}]}|'+'[PAM]' + #13#10 + 'DecimalesLitros=2' + #13#10 +
//            'DecimalesPesos=1' + #13#10 + 'DecimalesPrecio=1' + #13#10 +'DecimalesPrefijadoLitros=2' + #13#10 +
//            'DecimalesPrefijadoPesos=2' + #13#10 +'DecimalesTotalizadorLitros=2' + #13#10 +'DecimalesTotalizadorPesos=2' + #13#10 +
//            'DigitosPesos=6' + #13#10 +'NivelPrecio=1' + #13#10 +'ResetPAM=0' + #13#10 +'TiempoEntreComandos=300' + #13#10 +
//            'VentaMaximaLitros=999' + #13#10 +'VentaMaximaPesos=9999|';
      json:='|DISPENSERS|INITIALIZE|{"Consoles":[{"ConsoleId":1,"Connection":"SERIAL,COM4,5760,E,8,1","Protocol":"Hong Yang","LastDispenser":1}],"Products":[{"ProductId":2,"Name":"PREMIUM","Price":21},'+
            '{"ProductId":1,"Name":"MAGNA","Price":19},{"ProductId":3,"Name":"DIESEL","Price":20}],"Dispensers":[{"DispenserId":1,"MaximumSale":9999,"Units":"MONEY","OperationMode":"FULLSERVICE",'+
            '"Blocked":false,"Hoses":[{"HoseId":1,"ProductId":1}]}]}|DIGITOSGILBARCO=6';


      jsonT:= '|TANKS|INITIALIZE|{"Consoles":[{"ConsoleId":1,"Connection":"SERIAL,COM3,9600,N,8,1","Protoc'+
              'ol":"VEEDER ROOT","LastTank":1},{"ConsoleId":2,"Connection":"IP,192.168.1.222:10001","Protocol":"VEEDER ROOT",'+
              '"LastTank":1}],"Products":[{"ProductId":1,"Name":"REGULAR","Price":20},{"ProductId":2,"Name":"PREMIUM","Pri'+
              'ce":21}],"Tanks":[{"TankId":1,"ProductId":1},{"TankId":2,"ProductId":2},{"TankId":3,"ProductId":2}]}|';

      jsonP:= '|DISPENSERS|PARAMETERS|{"AllowedCommErrors":5,"AllowNonWorkingPosition":0,"AllowedZeroSales":5,"CentsToRound":0,'+
              '"CounterToAuthorizeSale":2,"CounterToFinalizeSale":2,"CounterToPaySale":30,"Interval":900,"LoadSalesProgress":1,'+
              '"PriceChangeAtStartup":0,"ProvisionTimeout":180,"SaveZeroSales":1,"Log":{"Commands":0,"Communications":0,"Connections":0,"LogId":0}}|';

      if ComboBox1.ItemIndex=0 then
        mensaje:=json
      else if ComboBox1.ItemIndex=1 then
        mensaje:=jsonT
      else if ComboBox1.ItemIndex=2 then
        mensaje:=jsonP
      else
        mensaje:=ComboBox2.Text;
      if CheckBox1.Checked then
        ClientSocket1.Socket.SendText(#1+'a13f'+#2+mensaje+#3+CRC16(mensaje)+#23)
      else
        ClientSocket1.Socket.SendText(Encrypt(#1+'a13f'+#2+mensaje+#3+CRC16(mensaje)+#23,key3DES));

    end
    else begin
      MensajeErr('No fue posible establecer conexión.');
      Abort;
    end;
  except
    on e:Exception do begin
      MensajeErr(e.Message);
      Button1.Enabled:=True
    end;
  end;
end;

procedure TForm1.ClientSocket1Read(Sender: TObject;
  Socket: TCustomWinSocket);
  var
    i:Integer;
    lin,lin2:string;
begin
  if CheckBox1.Checked then
    lin:=Socket.ReceiveText
  else
    lin:=Decrypt(Socket.ReceiveText,key3DES); 
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
  ListBox1.Items.Add(lin2);
  ClientSocket1.Active:=False;
  Button1.Enabled:=True;
  Button2.Enabled:=True;
  Button3.Enabled:=True;
end;

procedure TForm1.ClientSocket1Connect(Sender: TObject;
  Socket: TCustomWinSocket);
begin
  conectado:=True;
end;

procedure TForm1.ClientSocket1Disconnect(Sender: TObject;
  Socket: TCustomWinSocket);
begin
  conectado:=False;
end;

procedure TForm1.Edit1KeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  Button1.Enabled:=ComboBox2.Text<>'';
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  ListBox1.Clear;
  Button2.Enabled:=False;
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
  ListBox1.Items.SaveToFile('respuestas.txt');
end;


function TForm1.CRC16(Data: AnsiString): AnsiString;
var
  aCrc:TCRC;
  cad :string;
  pin : Pointer;
  insize:Cardinal;
  crcDesc:TCRCDescription;
begin
  insize:=Length(Data);
  pin:=@Data[1];
  aCrc:=TCRC.Create(CRC16Desc);
  aCrc.CalcBlock(pin,insize);
  Result:=IntToHex(aCrc.Finish,4)
end;

procedure TForm1.ComboBox1Click(Sender: TObject);
begin
  Button1.Enabled:=(ComboBox1.ItemIndex<3) or (ComboBox2.Text<>'');
  ComboBox2.Enabled:=ComboBox1.ItemIndex>2;
end;

procedure TForm1.FormShow(Sender: TObject);
begin
//  Key := THaspOG.Login(VendorCode,'853904027985621719');
////  Key := THaspOG.Login(VendorCode,'68024784424090124');
//  if Key.Status<>0 then
//    MensajeErr('Licencia inválida: '+Key.StatusMessage);
end;

function TForm1.Decrypt(data, key3DES: string): string;
var
  key128 : TKey128;
  dataOut : string;
begin
  GenerateMD5Key(key128, Key3DES);
  TripleDESEncryptString(data,dataOut,key128,false);
  dataOut := UTF8Decode(dataOut);
  Result := dataOut;
end;


function TForm1.Encrypt(data, key3DES: string): string;
var
  key128 : TKey128;
  dataIn,dataOut : string;
begin
  dataIn := UTF8Encode(data);
  GenerateMD5Key(key128, Key3DES);
  TripleDESEncryptString(dataIn,dataOut,key128,true);
  Result := dataOut;
end;

end.

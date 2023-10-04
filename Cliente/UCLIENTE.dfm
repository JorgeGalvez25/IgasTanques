object Form1: TForm1
  Left = 156
  Top = 96
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSingle
  Caption = 'Cliente Sockets'
  ClientHeight = 353
  ClientWidth = 878
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poMainFormCenter
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 18
    Top = 56
    Width = 37
    Height = 13
    Caption = 'Licencia'
  end
  object Button1: TButton
    Left = 401
    Top = 63
    Width = 75
    Height = 25
    Caption = 'Enviar'
    Default = True
    TabOrder = 3
    OnClick = Button1Click
  end
  object ListBox1: TListBox
    Left = 20
    Top = 118
    Width = 838
    Height = 175
    ItemHeight = 13
    TabOrder = 6
  end
  object Button2: TButton
    Left = 269
    Top = 308
    Width = 75
    Height = 25
    Caption = 'Limpiar'
    Default = True
    Enabled = False
    TabOrder = 7
    OnClick = Button2Click
  end
  object Button3: TButton
    Left = 533
    Top = 308
    Width = 75
    Height = 25
    Caption = 'Guardar'
    Default = True
    Enabled = False
    TabOrder = 8
    OnClick = Button3Click
  end
  object ComboBox1: TComboBox
    Left = 18
    Top = 22
    Width = 145
    Height = 21
    Style = csDropDownList
    ItemHeight = 13
    ItemIndex = 0
    TabOrder = 1
    Text = 'Ini Disp'
    OnClick = ComboBox1Click
    Items.Strings = (
      'Ini Disp'
      'Ini Tanq'
      'Para Disp'
      'Cmd')
  end
  object Edit2: TEdit
    Left = 723
    Top = 21
    Width = 121
    Height = 21
    TabOrder = 0
    Text = '127.0.0.1:1001'
  end
  object ComboBox2: TComboBox
    Left = 200
    Top = 22
    Width = 428
    Height = 21
    Enabled = False
    ItemHeight = 13
    TabOrder = 2
    Text = 'DISPENSERS|RUN'
    Items.Strings = (
      'DISPENSERS|RUN'
      'DISPENSERS|AUTHORIZE|1|1|50||1|'
      'DISPENSERS|TRACE'
      'DISPENSERS|STATUS|0'
      'DISPENSERS|STOP|1'
      'DISPENSERS|RESPCMND|1'
      'DISPENSERS|PAYMENT|1'
      'DISPENSERS|TOTALS|1'
      'DISPENSERS|TRANSACTION|1'
      'DISPENSERS|PRICES|17|18|19||'
      'DISPENSERS|HALT'
      'DISPENSERS|TERMINATE'
      'DISPENSERS|SHUTDOWN')
  end
  object CheckBox1: TCheckBox
    Left = 575
    Top = 73
    Width = 97
    Height = 17
    Caption = 'Limpio'
    TabOrder = 4
  end
  object Edit1: TEdit
    Left = 18
    Top = 75
    Width = 121
    Height = 21
    TabOrder = 5
    Text = '446766839753401779'
  end
  object ClientSocket1: TClientSocket
    Active = False
    ClientType = ctNonBlocking
    Host = '127.0.0.1'
    Port = 8585
    OnConnect = ClientSocket1Connect
    OnDisconnect = ClientSocket1Disconnect
    OnRead = ClientSocket1Read
    Left = 304
    Top = 49
  end
end

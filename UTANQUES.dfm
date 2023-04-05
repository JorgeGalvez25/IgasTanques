object ogcvtanques: Togcvtanques
  OldCreateOrder = False
  DisplayName = 'OpenGas Tanques'
  OnExecute = ServiceExecute
  Left = 299
  Top = 208
  Height = 202
  Width = 317
  object ServerSocket1: TServerSocket
    Active = False
    Port = 8585
    ServerType = stNonBlocking
    OnClientRead = ServerSocket1ClientRead
    Left = 64
    Top = 31
  end
  object pSerial: TApdComPort
    TraceName = 'APRO.TRC'
    LogName = 'APRO.LOG'
    OnTriggerAvail = pSerialTriggerAvail
    Left = 120
    Top = 29
  end
  object TM_Tanques: TRxMemoryData
    FieldDefs = <>
    Left = 180
    Top = 33
    object TM_TanquesCLAVE: TIntegerField
      FieldName = 'CLAVE'
    end
    object TM_TanquesVOLUMEN: TFloatField
      FieldName = 'VOLUMEN'
    end
    object TM_TanquesVOLUMENTC: TFloatField
      FieldName = 'VOLUMENTC'
    end
    object TM_TanquesVOLUMENAGUA: TFloatField
      FieldName = 'VOLUMENAGUA'
    end
    object TM_TanquesPORLLENAR: TFloatField
      FieldName = 'PORLLENAR'
    end
    object TM_TanquesTEMPERATURA: TFloatField
      FieldName = 'TEMPERATURA'
    end
    object TM_TanquesESTATUS: TStringField
      FieldName = 'ESTATUS'
      Size = 15
    end
  end
  object Timer1: TTimer
    Enabled = False
    Interval = 1500
    OnTimer = Timer1Timer
    Left = 57
    Top = 102
  end
  object TM_Entradas: TRxMemoryData
    FieldDefs = <>
    Left = 178
    Top = 105
    object TM_EntradasTANQUE: TIntegerField
      FieldName = 'TANQUE'
    end
    object TM_EntradasVOLUMENININETO: TFloatField
      FieldName = 'VOLUMENININETO'
    end
    object TM_EntradasVOLUMENFINNETO: TFloatField
      FieldName = 'VOLUMENFINNETO'
    end
    object TM_EntradasVOLUMENINIBRUTO: TFloatField
      FieldName = 'VOLUMENINIBRUTO'
    end
    object TM_EntradasVOLUMENFINBRUTO: TFloatField
      FieldName = 'VOLUMENFINBRUTO'
    end
    object TM_EntradasTEMPERATURA: TFloatField
      FieldName = 'TEMPERATURA'
    end
    object TM_EntradasFECHAHORAINI: TDateTimeField
      FieldName = 'FECHAHORAINI'
    end
    object TM_EntradasFECHAHORAFIN: TDateTimeField
      FieldName = 'FECHAHORAFIN'
    end
  end
  object Timer2: TTimer
    Enabled = False
    Interval = 60000
    OnTimer = Timer2Timer
    Left = 102
    Top = 103
  end
end

object Form1: TForm1
  Left = 175
  Top = 200
  Width = 476
  Height = 384
  Color = clBtnFace
  Font.Charset = SHIFTJIS_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = #65325#65331' '#65328#12468#12471#12483#12463
  Font.Style = []
  Menu = MainMenu1
  OldCreateOrder = True
  Position = poScreenCenter
  OnActivate = FormActivate
  OnClose = FormClose
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 12
  object PageControl1: TPageControl
    Left = 0
    Top = 0
    Width = 468
    Height = 338
    ActivePage = TabSheet1
    Align = alClient
    TabIndex = 0
    TabOrder = 0
    object TabSheet1: TTabSheet
      Caption = 'LOG'
      object Memo1: TMemo
        Left = 0
        Top = 0
        Width = 460
        Height = 311
        Align = alClient
        ScrollBars = ssBoth
        TabOrder = 0
      end
    end
    object TabSheet2: TTabSheet
      Caption = 'ERROR'
      ImageIndex = 1
      object Memo2: TMemo
        Left = 0
        Top = 0
        Width = 460
        Height = 311
        Align = alClient
        ScrollBars = ssBoth
        TabOrder = 0
      end
    end
    object TabSheet3: TTabSheet
      Caption = 'STATUS'
      ImageIndex = 2
      object Panel1: TPanel
        Left = 0
        Top = 0
        Width = 460
        Height = 311
        Align = alClient
        BevelInner = bvLowered
        TabOrder = 0
        DesignSize = (
          460
          311)
        object GroupBox1: TGroupBox
          Left = 232
          Top = 8
          Width = 217
          Height = 65
          Caption = 'ServerThread '#65306
          TabOrder = 0
          object SvThreadActive: TLabel
            Left = 64
            Top = 16
            Width = 12
            Height = 12
            Caption = '00'
          end
          object SvThreadCount: TLabel
            Left = 80
            Top = 16
            Width = 78
            Height = 12
            Caption = '0000000000000'
          end
          object Label4: TLabel
            Left = 22
            Top = 16
            Width = 39
            Height = 12
            Alignment = taRightJustify
            Caption = 'Active :'
            Transparent = True
          end
        end
        object GroupBox2: TGroupBox
          Left = 232
          Top = 80
          Width = 217
          Height = 89
          Caption = 'Server Cgi '#65306
          TabOrder = 1
          object Label6: TLabel
            Left = 64
            Top = 16
            Width = 12
            Height = 12
            Caption = '00'
          end
          object Label2: TLabel
            Left = 22
            Top = 16
            Width = 39
            Height = 12
            Alignment = taRightJustify
            Caption = 'Active :'
          end
          object Label8: TLabel
            Left = 33
            Top = 32
            Width = 28
            Height = 12
            Alignment = taRightJustify
            Caption = 'Ping :'
          end
          object Label11: TLabel
            Left = 80
            Top = 32
            Width = 78
            Height = 12
            Caption = '0000000000000'
          end
          object Label12: TLabel
            Left = 64
            Top = 32
            Width = 12
            Height = 12
            Caption = '00'
          end
          object Label3: TLabel
            Left = 80
            Top = 16
            Width = 78
            Height = 12
            Caption = '0000000000000'
          end
          object Label1: TLabel
            Left = 33
            Top = 48
            Width = 28
            Height = 12
            Alignment = taRightJustify
            Caption = 'Join :'
          end
          object Label7: TLabel
            Left = 64
            Top = 48
            Width = 12
            Height = 12
            Caption = '00'
          end
          object Label9: TLabel
            Left = 80
            Top = 48
            Width = 78
            Height = 12
            Caption = '0000000000000'
          end
          object Label5: TLabel
            Left = 10
            Top = 64
            Width = 51
            Height = 12
            Alignment = taRightJustify
            Caption = 'Welcome :'
          end
          object Label10: TLabel
            Left = 80
            Top = 64
            Width = 78
            Height = 12
            Caption = '0000000000000'
          end
          object Label13: TLabel
            Left = 64
            Top = 64
            Width = 12
            Height = 12
            Caption = '00'
          end
        end
        object GroupBox3: TGroupBox
          Left = 8
          Top = 8
          Width = 217
          Height = 105
          Caption = 'Client Cgi '#65306
          TabOrder = 2
          object Label14: TLabel
            Left = 64
            Top = 16
            Width = 12
            Height = 12
            Caption = '00'
          end
          object Label15: TLabel
            Left = 80
            Top = 16
            Width = 78
            Height = 12
            Caption = '0000000000000'
          end
          object Label16: TLabel
            Left = 22
            Top = 16
            Width = 39
            Height = 12
            Alignment = taRightJustify
            Caption = 'Active :'
            Transparent = True
          end
          object Label22: TLabel
            Left = 22
            Top = 48
            Width = 39
            Height = 12
            Alignment = taRightJustify
            Caption = 'init tm :'
            Transparent = True
          end
          object Label23: TLabel
            Left = 14
            Top = 64
            Width = 47
            Height = 12
            Alignment = taRightJustify
            Caption = 'sync tm :'
            Transparent = True
          end
          object Label24: TLabel
            Left = 64
            Top = 32
            Width = 6
            Height = 12
            Caption = '0'
          end
          object Label25: TLabel
            Left = 64
            Top = 48
            Width = 6
            Height = 12
            Caption = '0'
          end
          object Label26: TLabel
            Left = 64
            Top = 64
            Width = 6
            Height = 12
            Caption = '0'
          end
          object Label27: TLabel
            Left = 136
            Top = 32
            Width = 6
            Height = 12
            Caption = '0'
          end
          object Label28: TLabel
            Left = 136
            Top = 48
            Width = 6
            Height = 12
            Caption = '0'
          end
          object Label29: TLabel
            Left = 136
            Top = 64
            Width = 6
            Height = 12
            Caption = '0'
          end
          object Label30: TLabel
            Left = 11
            Top = 80
            Width = 50
            Height = 12
            Alignment = taRightJustify
            Caption = 'node cnt :'
            Transparent = True
          end
          object Label31: TLabel
            Left = 64
            Top = 80
            Width = 6
            Height = 12
            Caption = '0'
          end
          object Label21: TLabel
            Left = 17
            Top = 32
            Width = 44
            Height = 12
            Alignment = taRightJustify
            Caption = 'ping tm :'
            Transparent = True
          end
        end
        object GroupBox4: TGroupBox
          Left = 8
          Top = 176
          Width = 441
          Height = 135
          Anchors = [akLeft, akTop, akRight, akBottom]
          Caption = #12288'Agent Cache'#12288
          TabOrder = 3
          object Memo5: TMemo
            Left = 2
            Top = 14
            Width = 437
            Height = 105
            Align = alClient
            ReadOnly = True
            ScrollBars = ssBoth
            TabOrder = 0
          end
        end
      end
    end
    object TabSheet4: TTabSheet
      Caption = 'OPTION1'
      ImageIndex = 3
      DesignSize = (
        460
        311)
      object Label17: TLabel
        Left = 16
        Top = 64
        Width = 177
        Height = 12
        Caption = 'DEFAULT LIST ( default_node.txt )'
      end
      object Label18: TLabel
        Left = 16
        Top = 184
        Width = 118
        Height = 12
        Caption = 'NODE LIST ( node.txt )'
      end
      object CheckBox1: TCheckBox
        Left = 16
        Top = 8
        Width = 97
        Height = 17
        Caption = 'LOG LEVEL 1'
        Checked = True
        State = cbChecked
        TabOrder = 0
      end
      object CheckBox2: TCheckBox
        Left = 120
        Top = 8
        Width = 97
        Height = 17
        Caption = 'LOG LEVEL 2'
        TabOrder = 1
      end
      object Memo3: TMemo
        Left = 16
        Top = 80
        Width = 433
        Height = 73
        Anchors = [akLeft, akTop, akRight]
        ScrollBars = ssVertical
        TabOrder = 2
      end
      object CheckBox3: TCheckBox
        Left = 224
        Top = 8
        Width = 97
        Height = 17
        Caption = 'ERROR LOG'
        TabOrder = 3
      end
      object Button3: TButton
        Left = 392
        Top = 60
        Width = 57
        Height = 17
        Caption = 'save'
        TabOrder = 4
        OnClick = Button3Click
      end
      object Memo4: TMemo
        Left = 16
        Top = 200
        Width = 433
        Height = 107
        Anchors = [akLeft, akTop, akRight, akBottom]
        ScrollBars = ssVertical
        TabOrder = 5
      end
      object Button4: TButton
        Left = 264
        Top = 164
        Width = 57
        Height = 17
        Caption = 'read'
        TabOrder = 6
        OnClick = Button4Click
      end
      object Button5: TButton
        Left = 264
        Top = 180
        Width = 57
        Height = 17
        Caption = 'save'
        TabOrder = 7
        OnClick = Button5Click
      end
      object Button6: TButton
        Left = 151
        Top = 180
        Width = 105
        Height = 17
        Caption = 'default list copy'
        TabOrder = 8
        OnClick = Button6Click
      end
      object CheckBox4: TCheckBox
        Left = 328
        Top = 8
        Width = 121
        Height = 17
        Caption = 'VERSION CHECK'
        TabOrder = 9
      end
      object CheckBox5: TCheckBox
        Left = 16
        Top = 27
        Width = 97
        Height = 17
        Caption = 'CLIENT CGI'
        Checked = True
        State = cbChecked
        TabOrder = 10
      end
      object CheckBox6: TCheckBox
        Left = 120
        Top = 27
        Width = 97
        Height = 17
        Caption = 'SERVER CGI'
        Checked = True
        State = cbChecked
        TabOrder = 11
      end
      object Button2: TButton
        Left = 328
        Top = 60
        Width = 57
        Height = 17
        Caption = 'read'
        TabOrder = 12
        OnClick = Button2Click
      end
      object Button7: TButton
        Left = 328
        Top = 164
        Width = 57
        Height = 17
        Caption = 'read A'
        TabOrder = 13
        OnClick = Button7Click
      end
      object Button8: TButton
        Left = 328
        Top = 180
        Width = 57
        Height = 17
        Caption = 'save A'
        TabOrder = 14
        OnClick = Button8Click
      end
      object Button9: TButton
        Left = 392
        Top = 164
        Width = 57
        Height = 17
        Caption = 'read B'
        TabOrder = 15
        OnClick = Button9Click
      end
      object Button10: TButton
        Left = 392
        Top = 180
        Width = 57
        Height = 17
        Caption = 'save B'
        TabOrder = 16
        OnClick = Button10Click
      end
      object CheckBox7: TCheckBox
        Left = 224
        Top = 27
        Width = 209
        Height = 17
        Caption = 'NO SEARCH NODE SERVER'
        TabOrder = 17
      end
    end
    object TabSheet5: TTabSheet
      Caption = 'OPTION2'
      ImageIndex = 4
      object Label19: TLabel
        Left = 43
        Top = 24
        Width = 43
        Height = 12
        Alignment = taRightJustify
        Caption = 'Bind IP :'
      end
      object Label20: TLabel
        Left = 24
        Top = 48
        Width = 62
        Height = 12
        Alignment = taRightJustify
        Caption = 'Listen Port :'
      end
      object EditBind: TEdit
        Left = 93
        Top = 21
        Width = 121
        Height = 20
        TabOrder = 0
        Text = '0.0.0.0'
      end
      object EditPort: TEdit
        Left = 93
        Top = 45
        Width = 92
        Height = 20
        TabOrder = 1
        Text = '8000'
      end
    end
  end
  object MainMenu1: TMainMenu
    Left = 384
    Top = 65528
    object File1: TMenuItem
      Caption = '&File'
      object Menu_Start1: TMenuItem
        Caption = '&Start'
        OnClick = Menu_Start1Click
      end
      object N1: TMenuItem
        Caption = '-'
      end
      object Exit1: TMenuItem
        Caption = '&Exit'
        OnClick = Exit1Click
      end
    end
  end
  object Timer1: TTimer
    Enabled = False
    Interval = 500
    OnTimer = Timer1Timer
    Left = 352
    Top = 65528
  end
end

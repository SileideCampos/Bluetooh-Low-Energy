unit UPrincipal;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Layouts, FMX.ListBox, FMX.Controls.Presentation, System.Bluetooth,
  System.Bluetooth.Components, FMX.TabControl, FMX.Objects, FMX.Edit,
  FMX.Memo.Types, FMX.ScrollBox, FMX.Memo, System.Permissions, System.Rtti;

type
  TFLocalizador = class(TForm)
    layMenu: TLayout;
    btnBuscaDispositivos: TSpeedButton;
    BLE: TBluetoothLE;
    tcPrincipal: TTabControl;
    tbiDispositivos: TTabItem;
    tbiServicos: TTabItem;
    lbDispositivos: TListBox;
    pnDispositivos: TPanel;
    lblDispositivos: TLabel;
    lbServicos: TListBox;
    pnServicos: TPanel;
    lblServicos: TLabel;
    pnCaracteristicas: TPanel;
    lblCaracteristicas: TLabel;
    Layout3: TLayout;
    btnConectar: TButton;
    btnLeitura: TCircle;
    mRetorno: TMemo;
    StyleBook1: TStyleBook;
    lbCaracteristicas: TListBox;
    ListBoxItem1: TListBoxItem;
    pnEnvio: TPopup;
    layBotoes: TLayout;
    btnCloseWrite: TButton;
    lblAlerta: TLabel;
    GroupBox1: TGroupBox;
    rbSend_1: TRadioButton;
    rbSend_0: TRadioButton;
    ListBoxItem2: TListBoxItem;
    procedure btnBuscaDispositivosClick(Sender: TObject);
    procedure BLEEndDiscoverDevices(const Sender: TObject;
      const ADeviceList: TBluetoothLEDeviceList);
    procedure BLEEndDiscoverServices(const Sender: TObject;
      const AServiceList: TBluetoothGattServiceList);
    procedure BLECharacteristicRead(const Sender: TObject;
      const ACharacteristic: TBluetoothGattCharacteristic;
      AGattStatus: TBluetoothGattStatus);
    procedure lbServicosItemClick(const Sender: TCustomListBox;
      const Item: TListBoxItem);
    procedure lbDispositivosItemClick(const Sender: TCustomListBox;
      const Item: TListBoxItem);
    procedure btnConectarClick(Sender: TObject);
    procedure BLEDescriptorRead(const Sender: TObject;
      const ADescriptor: TBluetoothGattDescriptor;
      AGattStatus: TBluetoothGattStatus);
    procedure rbSend_1Click(Sender: TObject);
    procedure rbSend_0Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnCloseWriteClick(Sender: TObject);
  private
    { Private declarations }
    FGattService: TBluetoothGattService;
    FBleDevice: TBluetoothLEDevice;
    FListBoxItemSelected: TListBoxItem;
    FCharacteristic: TBluetoothGattCharacteristic;
    procedure mostrarDetalhesCaracteristicas(
      pCaracteristica: TBluetoothGattCharacteristic);
    procedure readCharacteristic(Sender: TObject);
    procedure notifyCharacteristic(Sender: TObject);
    procedure writeCharacteristic(Sender: TObject);
    procedure enviarDados(pValor: Integer);
    procedure readDescriptor(Sender: TObject);
    function getNameCharacteristic(pUUIDName: string): string;
  public
    { Public declarations }
  end;

var
  FLocalizador: TFLocalizador;

const
  CaracterBattery = '2A19';
  CaracterHeartRate = '2A37';

implementation

{$R *.fmx}

//PERMISSÃO PARA LOCALIZAÇÃO

procedure TFLocalizador.FormShow(Sender: TObject);
begin
  pnEnvio.Visible := False;
  tcPrincipal.ActiveTab := tbiDispositivos;
  lbServicos.Items.Clear;
  lbCaracteristicas.Clear;
end;

procedure TFLocalizador.btnBuscaDispositivosClick(Sender: TObject);
begin
  BLE.Enabled := True;
  BLE.CancelDiscovery;
  BLE.DiscoverDevices(800);
end;

procedure TFLocalizador.BLEEndDiscoverDevices(const Sender: TObject;
  const ADeviceList: TBluetoothLEDeviceList);
begin
  lbDispositivos.Items.Clear;
  lbServicos.Items.Clear;
  lbCaracteristicas.Items.Clear;
  for var lDevice in ADeviceList do
  begin
    if not (lDevice.DeviceName.IsEmpty) then
      lbDispositivos.Items.AddObject(lDevice.DeviceName+'-'+lDevice.LastRSSI.ToString, lDevice);
  end;
end;

procedure TFLocalizador.lbDispositivosItemClick(const Sender: TCustomListBox;
  const Item: TListBoxItem);
begin
  btnLeitura.Fill.Color := TAlphaColorRec.Silver;
  FBleDevice := TBluetoothLEDevice(Item.Data);
end;

procedure TFLocalizador.btnConectarClick(Sender: TObject);
begin
  btnLeitura.Fill.Color := TAlphaColorRec.Silver;
  if (btnConectar.Text = 'Conectar') and (FBleDevice <> nil) then
  begin
    try
      BLE.Enabled := True;
      FBleDevice.DiscoverServices;
    finally
      btnConectar.Text := 'Desconectar';
    end;
  end
  else
  begin
    lbDispositivos.Clear;
    lbServicos.Clear;
    lbCaracteristicas.Clear;
    mRetorno.Lines.Clear;
    btnLeitura.Fill.Color := TAlphaColorRec.Silver;
    BLE.Enabled           := False;
    FBleDevice            := nil;
    btnConectar.Text      := 'Conectar';
  end;
end;

procedure TFLocalizador.BLEEndDiscoverServices(const Sender: TObject;
  const AServiceList: TBluetoothGattServiceList);
var
  lCount: Integer;
begin
  lbServicos.Clear;
  if (AServiceList.Count > 0) then
    btnLeitura.Fill.Color := TAlphaColorRec.Lime;

  for var lService in AServiceList do
  begin
    inc(lCount);
    lbServicos.Items.AddObject('['+ lCount.ToString+'] - '+lService.UUIDName+' '+lService.UUID.ToString, lService);
  end;
end;

function TFLocalizador.getNameCharacteristic(pUUIDName: string): string;
begin
  if trim(pUUIDName) = '' then
    result := 'Descrição Desconhecida'
  else
    result := pUUIDName;
end;

procedure TFLocalizador.lbServicosItemClick(const Sender: TCustomListBox;
  const Item: TListBoxItem);
var
  lListBoxItem: TListBoxItem;
begin
  if BLE.Enabled then
  begin
    FGattService := BLE.GetService(FBleDevice, TBluetoothGattService(Item.Data).UUID);
    for var lCharacteristc in FGattService.Characteristics do
    begin
      lListBoxItem := TListBoxItem.Create(lbCaracteristicas);
      lListBoxItem.Parent := lbCaracteristicas;
      lListBoxItem.StyleLookup := 'ListBoxItemCharacteristic';
      lListBoxItem.Height := 95;
      lListBoxItem.StylesData['characteristic']       := getNameCharacteristic(lCharacteristc.UUIDName);
      lListBoxItem.StylesData['uuid']                 := 'UUID: '+lCharacteristc.UUID.ToString;
      lListBoxItem.StylesData['valor']                := 'Valor: '+TEncoding.UTF8.GetString(lCharacteristc.Value);
      lListBoxItem.StylesData['valor.visible']        := (TBluetoothProperty.Read in lCharacteristc.Properties) ;
      lListBoxItem.StylesData['read.visible']         := (TBluetoothProperty.Read in lCharacteristc.Properties) ;
      lListBoxItem.StylesData['read.OnClick']         := TValue.From<TNotifyEvent>(readCharacteristic);
      lListBoxItem.StylesData['read.Tag']             := integer(lListBoxItem);
      lListBoxItem.StylesData['write.visible']        := (TBluetoothProperty.Write in lCharacteristc.Properties);
      lListBoxItem.StylesData['write.OnClick']        := TValue.From<TNotifyEvent>(writeCharacteristic);
      lListBoxItem.StylesData['write.Tag']            := integer(lListBoxItem);
      lListBoxItem.StylesData['notification.visible'] := (TBluetoothProperty.Notify in lCharacteristc.Properties) ;
      lListBoxItem.StylesData['notification.OnClick'] := TValue.From<TNotifyEvent>(notifyCharacteristic);
      lListBoxItem.StylesData['notification.Tag']     := integer(lListBoxItem);
      lListBoxItem.Tag := integer(lCharacteristc);

      if not (TBluetoothProperty.Read in lCharacteristc.Properties) then
        lListBoxItem.Height := lListBoxItem.Height - 18; //55

      lCharacteristc.GetDescriptor(lCharacteristc.UUID);
      if (lCharacteristc.Descriptors.Count > 0) then
      begin
        for var lDescriptor in lCharacteristc.Descriptors do
        begin
          lListBoxItem := TListBoxItem.Create(lbCaracteristicas);
          lListBoxItem.Parent := lbCaracteristicas;
          lListBoxItem.StyleLookup := 'ListBoxItemDescriptors';
          lListBoxItem.Height := 40;
          lListBoxItem.StylesData['uuid']                 := lDescriptor.UUID.ToString;
          lListBoxItem.StylesData['valor']                := TEncoding.UTF8.GetString(lDescriptor.GetCharacteristic.GetValue);
          lListBoxItem.StylesData['read.visible']         := (TBluetoothProperty.Read in lCharacteristc.Properties) ;
          lListBoxItem.StylesData['read.OnClick']         := TValue.From<TNotifyEvent>(readDescriptor);
          lListBoxItem.StylesData['read.Tag']             := integer(lListBoxItem);
          lListBoxItem.Tag  := integer(lDescriptor);
        end;
      end
      else
      begin
        lListBoxItem.StylesData['descriptors.visible'] := False;
        lListBoxItem.Height := lListBoxItem.Height - 22;
      end;
    end;
  end;
end;

procedure TFLocalizador.notifyCharacteristic(Sender: TObject);
var
  lCharacteristic: TBluetoothGattCharacteristic;
begin

  if Assigned(TListBoxItem((Sender as TFmxObject).Tag)) and
     (TListBoxItem((Sender as TFmxObject).Tag).Tag <> 0) then
  begin
    FListBoxItemSelected := TListBoxItem((Sender as TFmxObject).Tag);
    lCharacteristic := TBluetoothGattCharacteristic(TListBoxItem((Sender as TFmxObject).Tag).Tag);

    if (FListBoxItemSelected.StylesData['notification.Fill.Color'].AsType<TAlphaColor> = TAlphaColorRec.Silver) then
    begin
      if BLE.SubscribeToCharacteristic(FBLEDevice, lCharacteristic) then
        FListBoxItemSelected.StylesData['notification.Fill.Color'] := TAlphaColorRec.Lime;
    end
    else
    begin
      if BLE.UnSubscribeToCharacteristic(FBLEDevice, lCharacteristic) then
        FListBoxItemSelected.StylesData['notification.Fill.Color'] := TAlphaColorRec.Silver;
    end;
  end;
end;

procedure TFLocalizador.readCharacteristic(Sender: TObject);
var
  lCharacteristic: TBluetoothGattCharacteristic;
begin
  if Assigned(TListBoxItem((Sender as TFmxObject).Tag)) and
     (TListBoxItem((Sender as TFmxObject).Tag).Tag <> 0) then
  begin
    lCharacteristic := TBluetoothGattCharacteristic(TListBoxItem((Sender as TFmxObject).Tag).Tag);
    BLE.ReadCharacteristic(FBleDevice, lCharacteristic);

    FListBoxItemSelected := TListBoxItem((Sender as TFmxObject).Tag);
    FListBoxItemSelected.StylesData['read.Fill.Color'] := TAlphaColorRec.Lime;
  end;
end;

procedure TFLocalizador.readDescriptor(Sender: TObject);
var
  lDescriptor: TBluetoothGattDescriptor;
begin
  if Assigned(TListBoxItem((Sender as TFmxObject).Tag)) and
     (TListBoxItem((Sender as TFmxObject).Tag).Tag <> 0) then
  begin
    lDescriptor := TBluetoothGattDescriptor(TListBoxItem((Sender as TFmxObject).Tag).Tag);
    BLE.ReadDescriptor(FBleDevice, lDescriptor);

    FListBoxItemSelected := TListBoxItem((Sender as TFmxObject).Tag);
    FListBoxItemSelected.StylesData['read.Fill.Color'] := TAlphaColorRec.Lime;
  end;
end;

procedure TFLocalizador.BLECharacteristicRead(const Sender: TObject;
  const ACharacteristic: TBluetoothGattCharacteristic;
  AGattStatus: TBluetoothGattStatus);
begin
  if AGattStatus = TBluetoothGattStatus.Success then
    mostrarDetalhesCaracteristicas(ACharacteristic);
end;

procedure TFLocalizador.mostrarDetalhesCaracteristicas(pCaracteristica: TBluetoothGattCharacteristic);
var
  lUUIDCaracteristica: string;
  lValor: Int8;
begin
  lUUIDCaracteristica := pCaracteristica.UUID.ToString;
  mRetorno.Lines.Add(pCaracteristica.UUIDName);
  mRetorno.Lines.Add('UUID: '+pCaracteristica.UUID.ToString);
  try
    try
      if lUUIDCaracteristica.Contains(CaracterBattery) then
      begin
        try
          lValor :=  pCaracteristica.GetValueAsInt8;
        finally
          mRetorno.Lines.Add('Bateria: '+ lValor.ToString);
          FListBoxItemSelected.StylesData['valor'] := 'Valor: '+lValor.ToString+'%';
        end;
      end
      else if lUUIDCaracteristica.Contains(CaracterHeartRate) then
      begin
        mRetorno.Lines.Add('Heart Rate: '+ (pCaracteristica.Value[1] + (pCaracteristica.Value[2] * 16)).ToString);
        FListBoxItemSelected.StylesData['valor'] := 'Valor: '+ pCaracteristica.GetValueAsInteger(1, TBluetoothGattFormatType.Unsigned16bitInteger).ToString +' bmp';
      end
      else
      begin
        mRetorno.Lines.Add('Valor: '+ TEncoding.UTF8.GetString(pCaracteristica.Value) );
        FListBoxItemSelected.StylesData['valor'] := 'Valor: '+TEncoding.UTF8.GetString(pCaracteristica.Value);
      end;
    except
      mRetorno.Lines.Add('Problemas ao ler o valor!')
    end;
  finally
    FListBoxItemSelected.StylesData['read.Fill.Color'] := TAlphaColorRec.Silver;
  end;
end;

procedure TFLocalizador.BLEDescriptorRead(const Sender: TObject;
  const ADescriptor: TBluetoothGattDescriptor;
  AGattStatus: TBluetoothGattStatus);
begin
  if ADescriptor.Kind = TBluetoothDescriptorKind.ExtendedProperties then
  begin
    mRetorno.Lines.Add( 'ExtendedProperties' );
    if ADescriptor.ReliableWrite then
      mRetorno.Lines.Add( '    ReliableWrite' )
    else if ADescriptor.WritableAuxiliaries then
      mRetorno.Lines.Add( '    WritableAuxiliaries' )
  end
  else if ADescriptor.Kind = TBluetoothDescriptorKind.UserDescription then
  begin
    mRetorno.Lines.Add( 'UserDescription' );
    mRetorno.Lines.Add( '    '+ ADescriptor.UserDescription );
  end
  else if ADescriptor.Kind = TBluetoothDescriptorKind.ClientConfiguration then
  begin
    mRetorno.Lines.Add( 'ClientConfiguration' );
    if ADescriptor.Notification then
      mRetorno.Lines.Add( '    Notification' )
    else if ADescriptor.Indication then
      mRetorno.Lines.Add( '    Indication' )
  end
  else if ADescriptor.Kind = TBluetoothDescriptorKind.ServerConfiguration then
  begin
    mRetorno.Lines.Add( 'ServerConfiguration' );
    if ADescriptor.Broadcasts then
      mRetorno.Lines.Add( '    Broadcasts' );
  end
  else if ADescriptor.Kind = TBluetoothDescriptorKind.PresentationFormat then
  begin
    mRetorno.Lines.Add( 'PresentationFormat' );
    if ADescriptor.Format = TBluetoothGattFormatType.IEEE754_32bit_floating_point then
      mRetorno.Lines.Add('    32bits_Float' )
    else if ADescriptor.Format = TBluetoothGattFormatType.IEEE11073_16bitSFLOAT then
      mRetorno.Lines.Add( '    16bits_Float' )
    else if ADescriptor.Format in
            [TBluetoothGattFormatType.Unsigned2bitInteger, TBluetoothGattFormatType.Unsigned4bitInteger] then
      mRetorno.Lines.Add( '    INT_2/4_bits' )
    else if ADescriptor.Format in
            [TBluetoothGattFormatType.Unsigned8bitInteger, TBluetoothGattFormatType.Unsigned12bitInteger,
            TBluetoothGattFormatType.Unsigned16bitInteger, TBluetoothGattFormatType.Unsigned24bitInteger,
            TBluetoothGattFormatType.Unsigned32bitInteger, TBluetoothGattFormatType.Unsigned48bitInteger,
            TBluetoothGattFormatType.Unsigned64bitInteger]
    then
      mRetorno.Lines.Add( '    INT' )
    else if ADescriptor.Format = TBluetoothGattFormatType.Unsigned128bitInteger then
       mRetorno.Lines.Add( '    INT_11bits' )
    else if ADescriptor.Format in
            [TBluetoothGattFormatType.UTF8String, TBluetoothGattFormatType.UTF16String]
    then
      mRetorno.Lines.Add( '    UTF_String' );

    mRetorno.Lines.Add('    Exponent: '+ ADescriptor.Exponent.ToString );
    mRetorno.Lines.Add('    FormatUnit: '+ GUIDToString(ADescriptor.FormatUnit));
    mRetorno.Lines.Add('    FormatUnitName: '+ ADescriptor.GetKnownUnitName(ADescriptor.FormatUnit));
  end;

end;

procedure TFLocalizador.writeCharacteristic(Sender: TObject);
begin
  if Assigned(TListBoxItem((Sender as TFmxObject).Tag)) and
     (TListBoxItem((Sender as TFmxObject).Tag).Tag <> 0) then
  begin
    FCharacteristic := TBluetoothGattCharacteristic(TListBoxItem((Sender as TFmxObject).Tag).Tag);
    pnEnvio.Visible := True;
  end;
end;

procedure TFLocalizador.btnCloseWriteClick(Sender: TObject);
begin
  pnEnvio.Visible := False;
end;

procedure TFLocalizador.rbSend_0Click(Sender: TObject);
begin
  enviarDados(TRadioButton(Sender as TFMXObject).Tag);
end;

procedure TFLocalizador.rbSend_1Click(Sender: TObject);
begin
  enviarDados(TRadioButton(Sender as TFMXObject).Tag);
end;

procedure TFLocalizador.enviarDados(pValor: Integer);
begin
  FCharacteristic.SetValueAsInteger(pValor);
  FBleDevice.WriteCharacteristic(FCharacteristic);
end;

end.

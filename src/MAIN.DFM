�
 TMAINFORM 0T  TPF0	TMainFormMainFormLeft+Top� Width�Height�CaptionOld'aVista Chat!
Font.ColorclWindowTextFont.Height�	Font.NameSystem
Font.Style PixelsPerInch`
OnActivateFormActivateOnCreate
FormCreate	OnDestroyFormDestroyOnResize
FormResizeOnShowFormShow
TextHeight TPanelMessagePanelLeft Top�Width�Height$AlignalBottom
BevelOuterbvNoneTabOrder  TEditEditMessageLeftTopWidthHeightEnabledTabOrder 
OnKeyPressEditMessageKeyPress  TButtonBtnSendLeft&TopWidthYHeightCaptionSendEnabledTabOrderOnClickBtnSendClick   TFatMemoChatMemoLeft Top WidthHeight�AlignalClient
Font.ColorclWindowTextFont.Height�	Font.NameFixedSys
Font.Style 
ParentFontColorclWindowBorderStylebsNoneTopIndex 
LineHeight	DrawFlags
dfWordWrapdfAlignBottom 	StickTextstBottomScrollBarVert	ScrollBarHoriz  TPanelPanel2Left Top�Width�Height AlignalBottom
BevelOuterbvNoneBorderWidthCaptionPanel2TabOrder TPanelStatusPanelLeftTopWidth� HeightAlignalLeft	AlignmenttaLeftJustify
BevelOuter	bvLoweredBorderWidthCaptionStatusPanelTabOrder   TPanelPanel4Left� TopWidth�HeightAlignalClient
BevelOuter	bvLoweredCaptionPanel4TabOrder  TPanel	SeparatorLeft� TopWidthHeightAlignalLeft
BevelOuterbvNoneTabOrder   TListBox	UsersListLeftTop WidthyHeight�AlignalRightEnabled
ItemHeightStylelbOwnerDrawFixedTabOrder
OnDrawItemUsersListDrawItem  TWSocket
CommSocketLineMode	LineLimit�� LineEnd
LineEchoLineEditPrototcp	LocalAddr0.0.0.0	LocalPort0MultiThreaded		MultiCastMultiCastIpTTL	ReuseAddrComponentOptions ListenBacklog	ReqVerLow
ReqVerHighOnDataAvailableCommSocketDataAvailable
OnSendDataCommSocketSendDataOnSessionClosedCommSocketSessionClosedOnSessionConnectedCommSocketSessionConnectedOnSocksConnectedCommSocketSocksConnectedFlushTimeout<	SendFlagswsSendNormalLingerOnOff
wsLingerOnLingerTimeout 
SocksLevel5SocksAuthenticationsocksNoAuthenticationLeft8Topp   
�
 TWEBSERVFORM 0�  TPF0TWebServFormWebServFormLeftWTopoWidth6Height6Caption+ICS WebServer Demo - http://www.overbyte.beColor	clBtnFaceFont.CharsetDEFAULT_CHARSET
Font.ColorclWindowTextFont.Height�	Font.NameMS Sans Serif
Font.Style OldCreateOrder	OnClose	FormCloseOnCreate
FormCreate	OnDestroyFormDestroyOnShowFormShowPixelsPerInch`
TextHeight TPanel
ToolsPanelLeft Top Width.HeightiAlignalTopTabOrder  TLabelLabel1Left&TopWidth!HeightCaptionDocDir  TLabelLabel2LeftTopWidth6HeightCaption
DefaultDoc  TLabelLabel3LeftTopWidthHeightCaptionPort  TLabelClientCountLabelLefthTopTWidthPHeightCaptionClientCountLabel  TLabelLabel5LeftDTopTWidthHeightCaptionClients  TLabelLabel4LeftTopPWidth2HeightCaption	Redir URL  TLabelLabel6LeftTop7Width9HeightCaptionTemplateDir  TEdit
DocDirEditLeftPTopWidth� HeightTabOrder Text
DocDirEdit  TEditDefaultDocEditLeftPTopWidth� HeightTabOrderTextDefaultDocEdit  TButtonStartButtonLeft Top4Width5HeightCaption&StartTabOrder	OnClickStartButtonClick  TButton
StopButtonLeft TopLWidth5HeightCaptionSt&opTabOrder
OnClickStopButtonClick  TEditPortEditLeft TopWidth5HeightTabOrderTextPortEdit  TButtonClearButtonLeft<Top4Width5HeightCaption&ClearTabOrderOnClickClearButtonClick  	TCheckBoxDisplayHeaderCheckBoxLeft�TopDWidthaHeight	AlignmenttaLeftJustifyCaptionDisplay HeaderTabOrder  	TCheckBoxWriteLogFileCheckBoxLeft�Top0WidthaHeight	AlignmenttaLeftJustifyCaptionWrite to log fileTabOrderOnClickWriteLogFileCheckBoxClick  	TCheckBoxDirListCheckBoxLeft�TopWidthUHeight	AlignmenttaLeftJustifyCaptionAllow Dir ListTabOrder  	TCheckBoxOutsideRootCheckBoxLeft�TopWidthqHeight	AlignmenttaLeftJustifyCaptionAllow Outside RootTabOrder  TEditRedirURLEditLeftPTopLWidth� HeightHint7Enter here the URL used for the redir.htm virtual page.ParentShowHintShowHint	TabOrderTextRedirURLEdit  TEditTemplateDirEditLeftPTop4Width� HeightTabOrderTextTemplateDirEdit   TMemoDisplayMemoLeft TopiWidth.Height� AlignalClientFont.CharsetDEFAULT_CHARSET
Font.ColorclWindowTextFont.Height�	Font.NameCourier New
Font.Style Lines.StringsDisplayMemo 
ParentFont
ScrollBarsssBothTabOrderWordWrap  THttpServerHttpServer1ListenBacklogPort80Addr0.0.0.0
MaxClients DocDir	\WebShareTemplateDirc:\wwwroot\templates
DefaultDoc
index.htmlLingerOnOffwsLingerNoSetLingerTimeoutOptions OnServerStartedHttpServer1ServerStartedOnServerStoppedHttpServer1ServerStoppedOnClientConnectHttpServer1ClientConnectOnClientDisconnectHttpServer1ClientDisconnectOnGetDocumentHttpServer1GetDocumentOnHeadDocumentHttpServer1HeadDocumentOnPostDocumentHttpServer1PostDocumentOnPostedDataHttpServer1PostedDataLeft\Top�    
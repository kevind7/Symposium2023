program FaceDetection;

uses
  {$IFDEF EurekaLog}
  EMemLeaks,
  EResLeaks,
  EDebugExports,
  EDebugJCL,
  EFixSafeCallException,
  EMapWin32,
  EAppVCL,
  EDialogWinAPIMSClassic,
  EDialogWinAPIEurekaLogDetailed,
  EDialogWinAPIStepsToReproduce,
  ExceptionLog7,
  {$ENDIF EurekaLog}
  Vcl.Forms,
  frmFaceWindow in 'frmFaceWindow.pas' {frmFaceDetection},
  uBaseFaceRecognition in '..\Libs\FaceRecognition\uBaseFaceRecognition.pas',
  uMicrosoft.FaceRecognition in '..\Libs\FaceRecognition\uMicrosoft.FaceRecognition.pas',
  REST.Authenticator.EnhancedOAuth in '..\Libs\REST.Authenticator.EnhancedOAuth.pas',
  uGoogle.FaceRecognition in '..\Libs\FaceRecognition\uGoogle.FaceRecognition.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmFaceDetection, frmFaceDetection);
  Application.Run;
end.

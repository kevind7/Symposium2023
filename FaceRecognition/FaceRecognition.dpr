program FaceRecognition;

uses
  Vcl.Forms,
  frmFaceWindow in 'frmFaceWindow.pas' {frmFaceDetection},
  uBaseFaceRecognition in '..\Libs\FaceRecognition\uBaseFaceRecognition.pas',
  uMicrosoft.FaceRecognition in '..\Libs\FaceRecognition\uMicrosoft.FaceRecognition.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmFaceDetection, frmFaceDetection);
  Application.Run;
end.

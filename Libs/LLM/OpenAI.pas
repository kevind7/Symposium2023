unit OpenAI;

interface

uses
  System.Classes,
  System.JSON,
  System.SysUtils,
  System.Generics.Collections,
  REST.Client,
  REST.Types,
  uLLM
  ;

type
  TOpenAI = class(TBaseLLM)
  protected
    function GetModelInfo: TObjectList<TBaseModelInfo>; override;
  private
    procedure ListOpenAIModels(out AModelList: TStringList);
  public
    constructor Create(const APIKey: string);
    function ChatCompletion(ChatConfig: TChatSettings; AMessages: TObjectList<TChatMessage>): TChatResponse; override;
    function Completion(const AQuestion: string; const AModel: string): string; override;
    function Embeddings(const Texts: TArray<string>): TEmbeddings;
  end;

function CosineDistance(const Vector1, Vector2: TEmbedding): Double;

implementation

function CosineDistance(const Vector1, Vector2: TEmbedding): Double;
var
  DotProduct, Magnitude1, Magnitude2: Double;
  i: Integer;
begin
  DotProduct := 0;
  Magnitude1 := 0;
  Magnitude2 := 0;

  // Calculate dot product and magnitudes
  for i := 0 to Length(Vector1) - 1 do
  begin
    DotProduct := DotProduct + (Vector1[i] * Vector2[i]);
    Magnitude1 := Magnitude1 + Sqr(Vector1[i]);
    Magnitude2 := Magnitude2 + Sqr(Vector2[i]);
  end;

  Magnitude1 := Sqrt(Magnitude1);
  Magnitude2 := Sqrt(Magnitude2);

  // Calculate cosine distance
  Result := 1 - (DotProduct / (Magnitude1 * Magnitude2));
end;

function TOpenAI.ChatCompletion(ChatConfig: TChatSettings; AMessages: TObjectList<TChatMessage>): TChatResponse;
var
  LRESTClient: TRESTClient;
  LRESTRequest: TRESTRequest;
  LRESTResponse: TRESTResponse;
  LJSONBody: TJSONObject;
  LJSONMessages: TJSONArray;
  LJSONMsg : TJSONObject;
  LMessage: TChatMessage;
  LJSONResponse: TJSONObject;
  LChoices: TJSONArray;
  LUsage: TJSONObject;
  LChoice: TJSONObject;
begin
  Result := Default(TChatResponse);
  Result.Content := '';
  Result.Completion_Tokens := 0;
  Result.Prompt_Tokens := 0;
  Result.Total_Tokens := 0;
  LRESTClient := nil;
  LRESTRequest := nil;
  LRESTResponse := nil;
  try
    LRESTClient := TRESTClient.Create(nil);
    LRESTRequest := TRESTRequest.Create(nil);
    LRESTResponse := TRESTResponse.Create(nil);
    LRESTClient.BaseURL := 'https://api.openai.com';
    LRESTClient.Accept := 'application/json';
    LRESTClient.AcceptCharset := 'UTF-8';
    LRESTRequest.Client := LRESTClient;
    LRESTRequest.Response := LRESTResponse;
    LRESTRequest.Method := TRESTRequestMethod.rmPOST;
    LRESTRequest.Timeout := 80000; // Set the timeout as needed
    LRESTRequest.Resource := '/v1/chat/completions';
    LRESTRequest.Params.AddItem('Authorization', 'Bearer ' + FAPIKey, TRESTRequestParameterKind.pkHTTPHEADER, [poDoNotEncode]);
    LRESTRequest.Params.AddItem('Content-Type', 'application/json', TRESTRequestParameterKind.pkHTTPHEADER, [poDoNotEncode]);
    LJSONBody := TJSONObject.Create;
    LJSONMessages := TJSONArray.Create;
    try
      for LMessage in AMessages do
      begin
        LJSONMsg := TJSONObject.Create;
        LJSONMsg.AddPair('role', LMessage.Role.ToLower);
        LJSONMsg.AddPair('content', LMessage.Content);
        LJSONMessages.AddElement(LJSONMsg);
      end;

      if ChatConfig.model.IsEmpty then
        ChatConfig.model := 'gpt-3.5-turbo';

      LJSONBody.AddPair('model', ChatConfig.model);
      LJSONBody.AddPair('messages', LJSONMessages);
      if ChatConfig.max_tokens > 0 then
        LJSONBody.AddPair('max_tokens', ChatConfig.max_tokens);
      if ChatConfig.user.Length > 0 then
        LJSONBody.AddPair('user', ChatConfig.user);
      if ChatConfig.n > 0 then
        LJSONBody.AddPair('n', ChatConfig.n);

      LRESTRequest.AddBody(LJSONBody.ToString, TRESTContentType.ctAPPLICATION_JSON);
      LRESTRequest.Execute;
      if LRESTResponse.StatusCode = 200 then
      begin
        LJSONResponse := TJSONObject.ParseJSONValue(LRESTResponse.Content) as TJSONObject;
        try
          LChoices := LJSONResponse.GetValue<TJSONArray>('choices');
          if Assigned(LJSONResponse.GetValue('model')) then
            Result.Model := LJSONResponse.GetValue('model').Value;

          if Assigned(LJSONResponse.GetValue('id')) then
            Result.Log_Id := LJSONResponse.GetValue('id').Value;

          LUsage := LJSONResponse.GetValue<TJSONObject>('usage');
          LUsage.TryGetValue('completion_tokens', Result.Completion_Tokens);
          LUsage.TryGetValue('prompt_tokens', Result.Prompt_Tokens);
          LUsage.TryGetValue('total_tokens', Result.Total_Tokens);
          LChoice := LChoices.Items[0] as TJSONObject;
          Result.Content := LChoice.GetValue('message').GetValue<string>('content');
        finally
          FreeAndNil(LJSONResponse);
        end;
      end
      else
      begin
        raise Exception.CreateFmt('Error: %d - %s', [LRESTResponse.StatusCode, LRESTResponse.StatusText]);
      end;
    finally
      FreeAndNil(LJSONBody);
    end;
  finally
    FreeAndNil(LRESTClient);
    FreeAndNil(LRESTRequest);
    FreeAndNil(LRESTResponse);
  end;
end;

constructor TOpenAI.Create(const APIKey: string);
begin
  inherited Create(APIKey);
end;

function TOpenAI.Completion(const AQuestion: string; const AModel: string): string;
var
  LClient : TRESTClient;
  LRequest : TRESTRequest;
  LResponse : TRESTResponse;
  LJsonPostData : TJSONObject;
  LJsonValue: TJsonValue;
  LJsonArray: TJsonArray;
  LJSonString: TJsonString;
begin
  Result := '';
  LJsonPostData := nil;
  LClient := nil;
  LRequest := nil;
  LResponse := nil;

  try
    LJsonPostData := TJSONObject.Create;
    LJsonPostData.AddPair('model', AModel);
    LJsonPostData.AddPair('prompt', AQuestion);
    LJsonPostData.AddPair('max_tokens', TJSONNumber.Create(2048));
    LJsonPostData.AddPair('temperature', TJSONNumber.Create(0));

    LClient := TRESTClient.Create(nil);
    LRequest := TRESTRequest.Create(nil);
    LResponse := TRESTResponse.Create(nil);
    LRequest.Client := LClient;
    LRequest.Response := LResponse;

    LClient.ReadTimeout := 180000;

    // Use JSON for the REST API calls and set API KEY via Authorization header
    LRequest.AddAuthParameter('Authorization', 'Bearer ' + FAPIKey, TRESTRequestParameterKind.pkHTTPHEADER, [poDoNotEncode]);
    LRequest.Accept := '*/*';

    // Select HTTPS POST method, set POST data and specify endpoint URL
    LRequest.Method := rmPOST;
    LRequest.AddBody(LJsonPostData);
    LClient.BaseURL := 'https://api.openai.com';
    LRequest.Resource := '/v1/completions';

    // Execute the HTTPS POST request synchronously (last param Async = false)
    LRequest.Execute;
    // Process returned JSON when request was successful
    if LRequest.Response.StatusCode = 200 then
    begin
      LJsonValue := LResponse.JSONValue;
      LJsonValue := LJsonValue.GetValue<TJSonValue>('choices');
      if LJsonValue is TJSonArray then
      begin
        LJSonArray := LJsonValue as TJSonArray;
        LJSonString := LJSonArray.Items[0].GetValue<TJSONString>('text');
        Result := LJSonString.Value;
      end;
    end
    else
      raise Exception.Create('HTTP response code: ' + LResponse.StatusCode.ToString);
  finally
    FreeAndNil(LResponse);
    FreeAndNil(LRequest);
    FreeAndNil(LClient);
    FreeAndNil(LJsonPostData);
  end;
end;

function TOpenAI.Embeddings(const Texts: TArray<string>): TEmbeddings;
var
  LRestClient: TRESTClient;
  LRestRequest: TRESTRequest;
  LRestResponse: TRESTResponse;
  LJsonRequest: TJSONArray;
  LDataArray, LEmbeddingArray: TJSONArray;
  LJsonResponse : TJSONObject;
  LJson: TJSONObject;
  I, J: Integer;
begin
  LRestClient := nil;
  LRestRequest := nil;
  LRestResponse := nil;
  LJson := nil;

  try
    LRestClient := TRESTClient.Create(nil);
    LRestRequest := TRESTRequest.Create(nil);
    LRestResponse := TRESTResponse.Create(nil);

    LRestRequest.Client := LRestClient;
    LRestClient.BaseURL := 'https://api.openai.com';
    LRestRequest.Resource := '/v1/embeddings';
    LRestRequest.Response := LRestResponse;
    LRestRequest.Method := TRESTRequestMethod.rmPOST;

    LJsonRequest := TJSONArray.Create;
    for I := 0 to High(Texts) do
      LJsonRequest.AddElement(TJSONString.Create(Texts[I]));

    LJson := TJSONObject.Create;
    LJson.AddPair('input', LJsonRequest);

    LJson.AddPair('model', 'text-embedding-ada-002');

    LRestRequest.AddBody(LJson.ToString, TRESTContentType.ctAPPLICATION_JSON);
    LRestRequest.AddAuthParameter('Authorization', 'Bearer ' + FAPIKey, TRESTRequestParameterKind.pkHTTPHEADER, [poDoNotEncode]);
    LRestRequest.Execute;

    if LRestResponse.StatusCode = 200 then
    begin
      LJsonResponse := TJSONObject.ParseJSONValue(LRestResponse.Content) as TJSONObject;
      LDataArray := LJsonResponse.GetValue<TJSONArray>('data');
      SetLength(Result, LDataArray.Count);

      for I := 0 to LDataArray.Count - 1 do
      begin
        LEmbeddingArray := LDataArray.Items[I].GetValue<TJSONArray>('embedding');
        SetLength(Result[I], LEmbeddingArray.Count);
        for J := 0 to LEmbeddingArray.Count - 1 do
          Result[I][J] := (LEmbeddingArray.Items[J] as TJSONNumber).AsDouble;
      end;

      FreeAndNil(LJsonResponse);
    end
    else
      raise Exception.CreateFmt('Error: %d - %s', [LRestResponse.StatusCode, LRestResponse.StatusText]);

  finally
    FreeAndNil(LJson);
    FreeAndNil(LRestRequest);
    FreeAndNil(LRestClient);
  end;
end;

function TOpenAI.GetModelInfo: TObjectList<TBaseModelInfo>;
var
  LModelList : TStringList;
  LModel : string;
  LModelObj : TBaseModelInfo;
begin
  LModelList := TStringList.Create;
  try
    ListOpenAIModels(LModelList);
    FModelInfo.Clear;
    for LModel in LModelList do
    begin
      LModelObj := TBaseModelInfo.Create;
      LModelObj.modelName := LModel;
      FModelInfo.Add(LModelObj);
    end;
  finally
    FreeandNil(LModelList);
  end;
  Result := FModelInfo;
end;

procedure TOpenAI.ListOpenAIModels(out AModelList: TStringList);
var
  LRESTClient: TRESTClient;
  LRESTRequest: TRESTRequest;
  LRESTResponse: TRESTResponse;
  LJSONArray: TJSONArray;
  LJSONModel: TJSONObject;
  LBaseJSONObject: TJSONObject;
  i: Integer;
begin
  LRESTClient := nil;
  LRESTRequest := nil;
  LRESTResponse := nil;
  LBaseJSONObject := nil;

  try
    LRESTClient := TRESTClient.Create('https://api.openai.com');
    LRESTRequest := TRESTRequest.Create(nil);
    LRESTResponse := TRESTResponse.Create(nil);
    LRESTRequest.Client := LRESTClient;
    LRESTRequest.Resource := '/v1/models';
    LRESTRequest.Method := rmGET;
    LRESTRequest.Response := LRESTResponse;

    // Add your API key to the request header
    LRESTRequest.Params.AddItem('Authorization', 'Bearer ' + FAPIKey, pkHTTPHEADER, [poDoNotEncode]);

    LRESTRequest.Execute;

    if LRESTResponse.StatusCode = 200 then
    begin
      LBaseJSONObject := TJSONObject.ParseJSONValue(LRESTResponse.JSONText) as TJSONObject;
      try
        if LBaseJSONObject.TryGetValue<TJSONArray>('data', LJSONArray) then
        begin
          for i := 0 to LJSONArray.Count - 1 do
          begin
            LJSONModel := LJSONArray.Items[i] as TJSONObject;
            AModelList.Add(LJSONModel.GetValue<string>('id'));
          end;
        end;
      finally
        FreeAndNil(LBaseJSONObject);
      end;
    end;
  finally
    FreeAndNil(LRESTResponse);
    FreeAndNil(LRESTRequest);
    FreeAndNil(LRESTClient);
  end;
end;

end.

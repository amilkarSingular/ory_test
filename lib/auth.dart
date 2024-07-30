import 'package:universal_html/html.dart';

import 'package:dio/dio.dart';
import 'package:ory_client/ory_client.dart';
import 'package:one_of/one_of.dart';  
import 'package:built_value/json_object.dart';

class AuthService {
  final FrontendApi _ory;
  Session? _identity;

  AuthService(Dio dio) : _ory = OryClient(dio: dio).getFrontendApi();

  Future<bool> isAuthenticated(Dio dio) async {
    final client = OryClient(dio: dio);
    client.setApiKey('apikey', 'ory_pat_FC7k2ClI68FXA96C99Dz1m6FJPoS758m');
    final service = client.getFrontendApi();
    return service.toSession().then((resp) {
      if (resp.statusCode == 200) {
        _identity = resp.data;
        return true;
      }
      return false;
    }).catchError((error) {
      return false;
    });
  }

  Future logout() async {
    return _ory.createBrowserLogoutFlow().then((resp) {
      return _ory.updateLogoutFlow(token: resp.data!.logoutToken).then((resp) {
        window.location.reload();
      });
    });
  }

  Future<bool> authenticateWithPasskey(Dio dio) async {
    try {
      final client = OryClient(dio: dio);
      final frontendApi = client.getFrontendApi();
      final browser = await frontendApi.createBrowserRegistrationFlow();
      // Iterate through all nodes in the registration flow
      for (var node in browser.data!.ui.nodes) {
        print('Node name: ${node.attributes.oneOf.value}');
        print('Node type: ${node.type}');
        
        print('---'); // Separator between nodes
      }
      final csrfToken = browser.data!.ui.nodes.firstWhere((node) => 
        node.attributes.oneOf.value is UiNodeInputAttributes && 
        (node.attributes.oneOf.value as UiNodeInputAttributes).name == 'csrf_token'
      );
      final csrfTokenValue = (csrfToken.attributes.oneOf.value as UiNodeInputAttributes).value.toString();
      print('csrfToken: ${csrfTokenValue}');
      var body = UpdateRegistrationFlowWithPasskeyMethod(
        (b) => b
          ..method = 'passkey'
          ..csrfToken = csrfTokenValue
          ..traits = JsonObject({
            'email': 'as@singularagency.co',
          })          
      );
      final response = await frontendApi.updateRegistrationFlow(
        flow: browser.data!.id,
        updateRegistrationFlowBody: UpdateRegistrationFlowBody(  
        (b) => b.oneOf = OneOf.fromValue1(value: body)),     
      );
      // print(response);

      
      return false;
    } catch (error) {
      print(error);
      return false;
    }
  }


  get identity => _identity;
}
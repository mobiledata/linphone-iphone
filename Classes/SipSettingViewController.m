
/* SipSettingViewControllerController.m
 *
 * Copyright (C) 2012  Belledonne Comunications, Grenoble, France
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU Library General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */

#import "linphone/linphonecore_utils.h"
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>

#import "SipSettingViewController.h"
#import "LinphoneManager.h"
#import "MainTabViewController.h"
#import "UIAssistantTextField.h"
#import "UITextField+DoneButton.h"

@implementation SipSettingViewController

#pragma mark - Lifecycle Functions

//- (id)init {
//    self = [super initWithNibName:NSStringFromClass(self.class) bundle:[NSBundle mainBundle]];
//    if (self != nil) {
//        [[NSBundle mainBundle] loadNibNamed:@"SipSettingViewControllerScreens" owner:self options:nil];
//        mustRestoreView = NO;
//    }
//    return self;
//}


#pragma mark - ViewController Functions

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(registrationUpdateEvent:)
                                               name:kLinphoneRegistrationUpdate
                                             object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(configuringUpdate:)
                                               name:kLinphoneConfiguringStateUpdate
                                             object:nil];
    
    if (!mustRestoreView) {
        new_config = NULL;
        number_of_configs_before = bctbx_list_size(linphone_core_get_proxy_config_list(LC));
        [self resetTextFields];
    }
    mustRestoreView = NO;
    _outgoingView = DialerView.compositeViewDescription;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [NSNotificationCenter.defaultCenter removeObserver:self];
    
}

#pragma mark - Utils

- (void)resetLiblinphone {
    if (account_creator) {
        linphone_account_creator_unref(account_creator);
        account_creator = NULL;
    }
    [LinphoneManager.instance resetLinphoneCore];
    account_creator = linphone_account_creator_new(
                                                   LC, [LinphoneManager.instance lpConfigStringForKey:@"xmlrpc_url" inSection:@"assistant" withDefault:@""]
                                                   .UTF8String);
    linphone_account_creator_set_user_data(account_creator, (__bridge void *)(self));
    linphone_account_creator_cbs_set_is_account_used(linphone_account_creator_get_callbacks(account_creator),
                                                     assistant_is_account_used);
    linphone_account_creator_cbs_set_create_account(linphone_account_creator_get_callbacks(account_creator),
                                                    assistant_create_account);
    linphone_account_creator_cbs_set_activate_account(linphone_account_creator_get_callbacks(account_creator),
                                                      assistant_activate_account);
    linphone_account_creator_cbs_set_is_account_activated(linphone_account_creator_get_callbacks(account_creator),
                                                          assistant_is_account_activated);
    linphone_account_creator_cbs_set_recover_phone_account(linphone_account_creator_get_callbacks(account_creator),
                                                           assistant_recover_phone_account);
    linphone_account_creator_cbs_set_is_account_linked(linphone_account_creator_get_callbacks(account_creator),
                                                       assistant_is_account_linked);
    
}
- (void)loadAssistantConfig:(NSString *)rcFilename {
    NSString *fullPath = [@"file://" stringByAppendingString:[LinphoneManager bundleFile:rcFilename]];
    linphone_core_set_provisioning_uri(LC, fullPath.UTF8String);
    [LinphoneManager.instance lpConfigSetInt:1 forKey:@"transient_provisioning" inSection:@"misc"];
    
    [self resetLiblinphone];
}

- (void)reset {
    [LinphoneManager.instance removeAllAccounts];
    [self resetTextFields];
    _waitView.hidden = TRUE;
}


+ (NSString *)errorForStatus:(LinphoneAccountCreatorStatus)status {
    switch (status) {
        case LinphoneAccountCreatorCountryCodeInvalid:
            return NSLocalizedString(@"Invalid country code.", nil);
        case LinphoneAccountCreatorEmailInvalid:
            return NSLocalizedString(@"Invalid email.", nil);
        case LinphoneAccountCreatorUsernameInvalid:
            return NSLocalizedString(@"Invalid username.", nil);
        case LinphoneAccountCreatorUsernameTooShort:
            return NSLocalizedString(@"Username too short.", nil);
        case LinphoneAccountCreatorUsernameTooLong:
            return NSLocalizedString(@"Username too long.", nil);
        case LinphoneAccountCreatorUsernameInvalidSize:
            return NSLocalizedString(@"Username length invalid.", nil);
        case LinphoneAccountCreatorPhoneNumberTooShort:
        case LinphoneAccountCreatorPhoneNumberTooLong:
            return nil; /* this is not an error, just user has to finish typing */
        case LinphoneAccountCreatorPhoneNumberInvalid:
            return NSLocalizedString(@"Invalid phone number.", nil);
        case LinphoneAccountCreatorPasswordTooShort:
            return NSLocalizedString(@"Password too short.", nil);
        case LinphoneAccountCreatorPasswordTooLong:
            return NSLocalizedString(@"Password too long.", nil);
        case LinphoneAccountCreatorDomainInvalid:
            return NSLocalizedString(@"Invalid domain.", nil);
        case LinphoneAccountCreatorRouteInvalid:
            return NSLocalizedString(@"Invalid route.", nil);
        case LinphoneAccountCreatorDisplayNameInvalid:
            return NSLocalizedString(@"Invalid display name.", nil);
        case LinphoneAccountCreatorReqFailed:
            return NSLocalizedString(@"Failed to query the server. Please try again later", nil);
        case LinphoneAccountCreatorTransportNotSupported:
            return NSLocalizedString(@"Unsupported transport", nil);
        case LinphoneAccountCreatorErrorServer:
            return NSLocalizedString(@"Server error", nil);
        case LinphoneAccountCreatorAccountCreated:
        case LinphoneAccountCreatorAccountExist:
        case LinphoneAccountCreatorAccountExistWithAlias:
        case LinphoneAccountCreatorAccountNotCreated:
        case LinphoneAccountCreatorAccountNotExist:
        case LinphoneAccountCreatorAccountNotActivated:
        case LinphoneAccountCreatorAccountAlreadyActivated:
        case LinphoneAccountCreatorAccountActivated:
        case LinphoneAccountCreatorAccountLinked:
        case LinphoneAccountCreatorAccountNotLinked:
        case LinphoneAccountCreatorPhoneNumberNotUsed:
        case LinphoneAccountCreatorPhoneNumberUsedAlias:
        case LinphoneAccountCreatorPhoneNumberUsedAccount:
        case LinphoneAccountCreatorOK:
            
            break;
    }
    return nil;
}

- (void)configureProxyConfig {
    LinphoneManager *lm = LinphoneManager.instance;
    
    if (!linphone_core_is_network_reachable(LC)) {
        UIAlertController *errView = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Network Error", nil)
                                                                         message:NSLocalizedString(@"There is no network connection available, enable "
                                                                                                   @"WIFI or WWAN prior to configure an account",
                                                                                                   nil)
                                                                  preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {}];
        
        [errView addAction:defaultAction];
        [self presentViewController:errView animated:YES completion:nil];
        _waitView.hidden = YES;
        return;
    }
    
    // remove previous proxy config, if any
    if (new_config != NULL) {
        const LinphoneAuthInfo *auth = linphone_proxy_config_find_auth_info(new_config);
        linphone_core_remove_proxy_config(LC, new_config);
        if (auth) {
            linphone_core_remove_auth_info(LC, auth);
        }
    }
    
    // set transport
    NSString *type = [_transportSegment titleForSegmentAtIndex:[_transportSegment selectedSegmentIndex]];
    linphone_account_creator_set_transport(account_creator,
                                               linphone_transport_parse(type.lowercaseString.UTF8String));
    
    new_config = linphone_account_creator_configure(account_creator);
    
    if (new_config) {
        [lm configurePushTokenForProxyConfig:new_config];
        linphone_core_set_default_proxy_config(LC, new_config);
        // reload address book to prepend proxy config domain to contacts' phone number
        // todo: STOP doing that!
        [[LinphoneManager.instance fastAddressBook] reload];
    } else {
        UIAlertController *errView = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Assistant error", nil)
                                                                         message:NSLocalizedString(@"Could not configure your account, please check parameters or try again later",
                                                                                                   nil)
                                                                  preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {}];
        
        [errView addAction:defaultAction];
        [self presentViewController:errView animated:YES completion:nil];
        _waitView.hidden = YES;
        return;
    }
}

- (void)addDoneButtonRecursivelyInView:(UIView *)subview {
    for (UIView *child in [subview subviews]) {
        if ([child isKindOfClass:UITextField.class]) {
            UITextField *tf = (UITextField *)child;
            if (tf.keyboardType == UIKeyboardTypePhonePad || tf.keyboardType == UIKeyboardTypeNumberPad) {
                [tf addDoneButton];
            }
        }
        [self addDoneButtonRecursivelyInView:child];
    }
}

- (void)fillDefaultValues {
    [self resetTextFields];
    
    LinphoneProxyConfig *default_conf = linphone_core_create_proxy_config(LC);
    const char *identity = linphone_proxy_config_get_identity(default_conf);
    if (identity) {
        LinphoneAddress *default_addr = linphone_core_interpret_url(LC, identity);
        if (default_addr) {
            const char *domain = linphone_address_get_domain(default_addr);
            const char *username = linphone_address_get_username(default_addr);
            if (domain && strlen(domain) > 0) {
                _domain.text = [NSString stringWithUTF8String:domain];
            }
            if (username && strlen(username) > 0 && username[0] != '?') {
                _createUsername.text = [NSString stringWithUTF8String:username];
            }
        }
    }
    
    linphone_proxy_config_destroy(default_conf);
}

- (void)resetTextFields {
//    for (UIView *view in @[_loginView]) {
//        [SipSettingViewController cleanTextField:view];
//    }
    phone_number_length = 0;
}

- (void)prepareErrorLabels {
    [_createUsername showError:[SipSettingViewController errorForStatus:LinphoneAccountCreatorUsernameInvalid]
                         when:^BOOL(NSString *inputEntry) {
                             LinphoneAccountCreatorStatus s =
                             linphone_account_creator_set_username(account_creator, inputEntry.UTF8String);
                             if (s != LinphoneAccountCreatorOK) linphone_account_creator_set_username(account_creator, NULL);
                             _createUsername.errorLabel.text = [SipSettingViewController errorForStatus:s];
                             return s != LinphoneAccountCreatorOK;
                         }];
    
    [_password showError:[SipSettingViewController errorForStatus:LinphoneAccountCreatorPasswordTooShort]
                   when:^BOOL(NSString *inputEntry) {
                       LinphoneAccountCreatorStatus s =
                       linphone_account_creator_set_password(account_creator, inputEntry.UTF8String);
                       _password.errorLabel.text = [SipSettingViewController errorForStatus:s];
                       return s != LinphoneAccountCreatorOK;
                   }];
    
    [_domain showError:[SipSettingViewController errorForStatus:LinphoneAccountCreatorDomainInvalid]
                 when:^BOOL(NSString *inputEntry) {
                     LinphoneAccountCreatorStatus s =
                     linphone_account_creator_set_domain(account_creator, inputEntry.UTF8String);
                     _domain.errorLabel.text = [SipSettingViewController errorForStatus:s];
                     return s != LinphoneAccountCreatorOK;
                 }];
    
    [_displayName showError:[SipSettingViewController errorForStatus:LinphoneAccountCreatorDisplayNameInvalid]
                      when:^BOOL(NSString *inputEntry) {
                          LinphoneAccountCreatorStatus s = LinphoneAccountCreatorOK;
                          if (inputEntry.length > 0) {
                              s = linphone_account_creator_set_display_name(account_creator, inputEntry.UTF8String);
                              _displayName.errorLabel.text = [SipSettingViewController errorForStatus:s];
                          }
                          return s != LinphoneAccountCreatorOK;
                      }];
    
    [self shouldEnableNextButton];
    
}

- (void)shouldEnableNextButton {
//    BOOL invalidInputs = NO;
//    for (int i = 0; !invalidInputs && i < ViewElement_TextFieldCount; i++) {
//        ViewElement ve = (ViewElement)100+i;
//        if ([self findTextField:ve].isInvalid) {
//            invalidInputs = YES;
//            break;
//        }
//    }
//    
//    UISwitch *emailSwitch = (UISwitch *)[self findView:ViewElement_EmailFormView inView:self.contentView ofType:UISwitch.class];
//    if (!emailSwitch.isOn) {
//        [self findButton:ViewElement_NextButton].enabled = !invalidInputs;
//    }
}


#pragma mark - Event Functions

- (void)registrationUpdateEvent:(NSNotification *)notif {
    NSString *message = [notif.userInfo objectForKey:@"message"];
    [self registrationUpdate:[[notif.userInfo objectForKey:@"state"] intValue]
                    forProxy:[[notif.userInfo objectForKeyedSubscript:@"cfg"] pointerValue]
                     message:message];
}

- (void)registrationUpdate:(LinphoneRegistrationState)state
                  forProxy:(LinphoneProxyConfig *)proxy
                   message:(NSString *)message {
    // in assistant we only care about ourself
    if (proxy != new_config) {
        return;
    }
    
    switch (state) {
        case LinphoneRegistrationOk: {
            _waitView.hidden = true;
            
            [LinphoneManager.instance
             lpConfigSetInt:[NSDate new].timeIntervalSince1970 +
             [LinphoneManager.instance lpConfigIntForKey:@"link_account_popup_time" withDefault:84200]
             forKey:@"must_link_account_time"];
            [MainTabViewController.instance popToView:_outgoingView];
            break;
        }
        case LinphoneRegistrationNone:
        case LinphoneRegistrationCleared: {
            _waitView.hidden = true;
            break;
        }
        case LinphoneRegistrationFailed: {
            _waitView.hidden = true;
            UIAlertController *errView = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Registration failure", nil)
                                                                             message:message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                                    style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction * action) {}];
            
            UIAlertAction* continueAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Continue", nil)
                                                                     style:UIAlertActionStyleDefault
                                                                   handler:^(UIAlertAction * action) {
                                                                       [MainTabViewController.instance popToView:DialerView.compositeViewDescription];
                                                                   }];
            
            [errView addAction:defaultAction];
            [errView addAction:continueAction];
            [self presentViewController:errView animated:YES completion:nil];
            break;
        }
        case LinphoneRegistrationProgress: {
            _waitView.hidden = false;
            break;
        }
        default:
            break;
    }
}

- (void)configuringUpdate:(NSNotification *)notif {
    LinphoneConfiguringState status = (LinphoneConfiguringState)[[notif.userInfo valueForKey:@"state"] integerValue];
    
    _waitView.hidden = true;
    
    switch (status) {
        case LinphoneConfiguringSuccessful:
            // we successfully loaded a remote provisioned config, go to dialer
            [LinphoneManager.instance lpConfigSetInt:[NSDate new].timeIntervalSince1970
                                              forKey:@"must_link_account_time"];
            if (number_of_configs_before < bctbx_list_size(linphone_core_get_proxy_config_list(LC))) {
                LOGI(@"A proxy config was set up with the remote provisioning, skip assistant");
                [MainTabViewController.instance popToView:DialerView.compositeViewDescription];
            }
            
            break;
        case LinphoneConfiguringFailed: {
            NSString *error_message = [notif.userInfo valueForKey:@"message"];
            UIAlertController *errView = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Provisioning Load error", nil)
                                                                             message:error_message
                                                                      preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK"
                                                                    style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction * action) {}];
            
            [errView addAction:defaultAction];
            [self presentViewController:errView animated:YES completion:nil];
            break;
        }
            
        case LinphoneConfiguringSkipped:
        default:
            break;
    }
}

+ (NSString *)StringForXMLRPCError:(const char *)err {
#define IS(x) (strcmp(err, #x) == 0)
    if
        IS(ERROR_ACCOUNT_ALREADY_ACTIVATED)
        return NSLocalizedString(@"This account is already activated.", nil);
    if
        IS(ERROR_ACCOUNT_ALREADY_IN_USE)
        return NSLocalizedString(@"This account is already in use.", nil);
    if
        IS(ERROR_ACCOUNT_DOESNT_EXIST)
        return NSLocalizedString(@"This account does not exist.", nil);
    if
        IS(ERROR_ACCOUNT_NOT_ACTIVATED)
        return NSLocalizedString(@"This account is not activated yet.", nil);
    if
        IS(ERROR_ALIAS_ALREADY_IN_USE)
        return NSLocalizedString(@"This phone number is already used. Please type a different number. \nYou can delete "
                                 @"your existing account if you want to reuse your phone number.",
                                 nil);
    if
        IS(ERROR_ALIAS_DOESNT_EXIST)
        return NSLocalizedString(@"This alias does not exist.", nil);
    if
        IS(ERROR_EMAIL_ALREADY_IN_USE)
        return NSLocalizedString(@"This email address is already used.", nil);
    if
        IS(ERROR_EMAIL_DOESNT_EXIST)
        return NSLocalizedString(@"This email does not exist.", nil);
    if
        IS(ERROR_KEY_DOESNT_MATCH)
        return NSLocalizedString(@"The confirmation code is invalid. \nPlease try again.", nil);
    if
        IS(ERROR_PASSWORD_DOESNT_MATCH)
        return NSLocalizedString(@"Passwords do not match.", nil);
    if
        IS(ERROR_PHONE_ISNT_E164)
        return NSLocalizedString(@"Your phone number is invalid.", nil);
    if
        IS(ERROR_CANNOT_SEND_SMS)
        return NSLocalizedString(@"Server error, please try again later.", nil);
    if
        IS(ERROR_NO_PHONE_NUMBER)
        return NSLocalizedString(@"Please confirm your country code and enter your phone number.", nil);
    if IS(Missing required parameters)
        return NSLocalizedString(@"Missing required parameters", nil);
    if IS(ERROR_BAD_CREDENTIALS)
        return NSLocalizedString(@"Bad credentials, check your account settings", nil);
    if IS(ERROR_NO_PASSWORD)
        return NSLocalizedString(@"Please enter a password to your account", nil);
    if IS(ERROR_NO_EMAIL)
        return NSLocalizedString(@"Please enter your email", nil);
    if IS(ERROR_NO_USERNAME)
        return NSLocalizedString(@"Please enter a username", nil);
    if IS(ERROR_INVALID_CONFIRMATION)
        return NSLocalizedString(@"Your confirmation password doesn't match your password", nil);
    if IS(ERROR_INVALID_EMAIL)
        return NSLocalizedString(@"Your email is invalid", nil);
    
    if (!linphone_core_is_network_reachable(LC))
        return NSLocalizedString(@"There is no network connection available, enable "
                                 @"WIFI or WWAN prior to configure an account.",
                                 nil);
    
    return NSLocalizedString(@"Unknown error, please try again later.", nil);
}

- (void)showErrorPopup:(const char *)error {
    const char *err = error ? error : "";
    if (strcmp(err, "ERROR_BAD_CREDENTIALS") == 0) {
        UIAlertController *errView = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Registration failure", nil)
                                                                         message:[SipSettingViewController StringForXMLRPCError:err]
                                                                  preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {}];
        
        UIAlertAction* continueAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Continue", nil)
                                                                 style:UIAlertActionStyleDefault
                                                               handler:^(UIAlertAction * action) {
                                                                   [MainTabViewController.instance popToView:DialerView.compositeViewDescription];
                                                               }];
        
        defaultAction.accessibilityLabel = @"PopUpResp";
        [errView addAction:defaultAction];
        [errView addAction:continueAction];
        [self presentViewController:errView animated:YES completion:nil];
    } else if (strcmp(err, "ERROR_KEY_DOESNT_MATCH") == 0) {
        UIAlertController *errView =
        [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Account configuration issue", nil)
                                            message:[SipSettingViewController StringForXMLRPCError:err]
                                     preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *defaultAction = [UIAlertAction
                                        actionWithTitle:@"OK"
                                        style:UIAlertActionStyleDefault
                                        handler:^(UIAlertAction *action) {
                                            NSString *tmp_phone =
                                            [NSString stringWithUTF8String:linphone_account_creator_get_phone_number(account_creator)];
                                            int ccc = -1;
                                            LinphoneDialPlan dialplan = {0};
                                            char *nationnal_significant_number = NULL;
                                            ccc = linphone_dial_plan_lookup_ccc_from_e164(tmp_phone.UTF8String);
                                            if (ccc > -1) { /*e164 like phone number*/
                                                dialplan = *linphone_dial_plan_by_ccc_as_int(ccc);
                                                nationnal_significant_number = strstr(tmp_phone.UTF8String, dialplan.ccc);
                                                if (nationnal_significant_number) {
                                                    nationnal_significant_number += strlen(dialplan.ccc);
                                                }
                                            }
//
                                            linphone_account_creator_set_activation_code(account_creator, "");
                                    
                                            // Reset phone number in account_creator to be sure to let the user retry
                                            if (nationnal_significant_number) {
                                                linphone_account_creator_set_phone_number(account_creator, nationnal_significant_number,
                                                                                          dialplan.ccc);
                                            }
                                        }];
        
        defaultAction.accessibilityLabel = @"PopUpResp";
        [errView addAction:defaultAction];
        [self presentViewController:errView animated:YES completion:nil];
    } else {
        UIAlertController *errView = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Account configuration issue", nil)
                                                                         message:[SipSettingViewController StringForXMLRPCError:err]
                                                                  preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {}];
        
        [errView addAction:defaultAction];
        defaultAction.accessibilityLabel = @"PopUpResp";
        [self presentViewController:errView animated:YES completion:nil];
    }
}

- (void)isAccountUsed:(LinphoneAccountCreatorStatus)status withResp:(const char *)resp {
   
        if (status == LinphoneAccountCreatorAccountExist || status == LinphoneAccountCreatorAccountExistWithAlias) {
            if (linphone_account_creator_get_phone_number(account_creator) != NULL) {
                // Offer the possibility to resend a sms confirmation in some cases
                linphone_account_creator_is_account_activated(account_creator);
            } else {
                [self showErrorPopup:resp];
            }
        } else if (status == LinphoneAccountCreatorAccountNotExist) {
            NSString * language = [[NSLocale preferredLanguages] objectAtIndex:0];
            linphone_account_creator_set_language(account_creator, [[language substringToIndex:2] UTF8String]);
            linphone_account_creator_create_account(account_creator);
        } else {
            [self showErrorPopup:resp];
            
        }
    }

- (void) isAccountActivated:(const char *)resp {
    
        if( linphone_account_creator_get_phone_number(account_creator) == NULL) {
            [self configureProxyConfig];
            //TODO Tuong cmt
//            [MainTabViewController.instance changeCurrentView:AssistantLinkView.compositeViewDescription];
        } else {
            [MainTabViewController.instance changeCurrentView:DialerView.compositeViewDescription];
        }
   
}

#pragma mark - Account creator callbacks

void assistant_is_account_used(LinphoneAccountCreator *creator, LinphoneAccountCreatorStatus status, const char *resp) {
    SipSettingViewController *thiz = (__bridge SipSettingViewController *)(linphone_account_creator_get_user_data(creator));
    thiz.waitView.hidden = YES;
    [thiz isAccountUsed:status withResp:resp];
}

void assistant_create_account(LinphoneAccountCreator *creator, LinphoneAccountCreatorStatus status, const char *resp) {
    SipSettingViewController *thiz = (__bridge SipSettingViewController *)(linphone_account_creator_get_user_data(creator));
    thiz.waitView.hidden = YES;
    if (status == LinphoneAccountCreatorAccountCreated) {
//        if (linphone_account_creator_get_phone_number(creator)) {
//            NSString* phoneNumber = [NSString stringWithUTF8String:linphone_account_creator_get_phone_number(creator)];
//            thiz.activationSMSText.text = [NSString stringWithFormat:NSLocalizedString(@"We have sent a SMS with a validation code to %@. To complete your phone number verification, please enter the 4 digit code below:", nil), phoneNumber];
////            [thiz changeView:thiz.createAccountActivateSMSView back:FALSE animation:TRUE];
//        } else {
//            NSString* email = [NSString stringWithUTF8String:linphone_account_creator_get_email(creator)];
//            thiz.activationEmailText.text = [NSString stringWithFormat:NSLocalizedString(@" Your account is created. We have sent a confirmation email to %@. Please check your mails to validate your account. Once it is done, come back here and click on the button.", nil), email];
////            [thiz changeView:thiz.createAccountActivateEmailView back:FALSE animation:TRUE];
//        }
    } else {
        [thiz showErrorPopup:resp];
    }
}

void assistant_recover_phone_account(LinphoneAccountCreator *creator, LinphoneAccountCreatorStatus status,
                                     const char *resp) {
    SipSettingViewController *thiz = (__bridge SipSettingViewController *)(linphone_account_creator_get_user_data(creator));
    thiz.waitView.hidden = YES;
//    if (status == LinphoneAccountCreatorOK) {
//        NSString* phoneNumber = [NSString stringWithUTF8String:linphone_account_creator_get_phone_number(creator)];
//        thiz.activationSMSText.text = [NSString stringWithFormat:NSLocalizedString(@"We have sent a SMS with a validation code to %@. To complete your phone number verification, please enter the 4 digit code below:", nil), phoneNumber];
////        [thiz changeView:thiz.createAccountActivateSMSView back:FALSE animation:TRUE];
//    } else {
//        if(!resp) {
//            [thiz showErrorPopup:"ERROR_CANNOT_SEND_SMS"];
//        } else {
//            [thiz showErrorPopup:resp];
//        }
//    }
}

void assistant_activate_account(LinphoneAccountCreator *creator, LinphoneAccountCreatorStatus status,
                                const char *resp) {
    SipSettingViewController *thiz = (__bridge SipSettingViewController *)(linphone_account_creator_get_user_data(creator));
    thiz.waitView.hidden = YES;
    if (status == LinphoneAccountCreatorAccountActivated) {
        [thiz configureProxyConfig];
        [[NSNotificationCenter defaultCenter] postNotificationName:kLinphoneAddressBookUpdate object:NULL];
    } else if (status == LinphoneAccountCreatorAccountAlreadyActivated) {
        // in case we are actually trying to link account, let's try it now
        linphone_account_creator_activate_phone_number_link(creator);
    } else {
        [thiz showErrorPopup:resp];
    }
}

void assistant_is_account_activated(LinphoneAccountCreator *creator, LinphoneAccountCreatorStatus status,
                                    const char *resp) {
    SipSettingViewController *thiz = (__bridge SipSettingViewController *)(linphone_account_creator_get_user_data(creator));
    thiz.waitView.hidden = YES;
    if (status == LinphoneAccountCreatorAccountActivated) {
        [thiz isAccountActivated:resp];
    } else if (status == LinphoneAccountCreatorAccountNotActivated) {
        if (!IPAD || linphone_account_creator_get_phone_number(creator) != NULL) {
            //Re send SMS if the username is the phone number
            if (linphone_account_creator_get_username(creator) != linphone_account_creator_get_phone_number(creator) && linphone_account_creator_get_username(creator) != NULL) {
                [thiz showErrorPopup:"ERROR_ACCOUNT_ALREADY_IN_USE"];
//                [thiz findButton:ViewElement_NextButton].enabled = NO;
            } else {
                NSString * language = [[NSLocale preferredLanguages] objectAtIndex:0];
                linphone_account_creator_set_language(creator, [[language substringToIndex:2] UTF8String]);
                linphone_account_creator_recover_phone_account(creator);
            }
        } else {
            // TO DO : Re send email ?
            [thiz showErrorPopup:"ERROR_ACCOUNT_ALREADY_IN_USE"];
//            [thiz findButton:ViewElement_NextButton].enabled = NO;
        }
    } else {
        [thiz showErrorPopup:resp];
    }
}

void assistant_is_account_linked(LinphoneAccountCreator *creator, LinphoneAccountCreatorStatus status,
                                 const char *resp) {
    SipSettingViewController *thiz = (__bridge SipSettingViewController *)(linphone_account_creator_get_user_data(creator));
    thiz.waitView.hidden = YES;
    if (status == LinphoneAccountCreatorAccountLinked) {
        [LinphoneManager.instance lpConfigSetInt:0 forKey:@"must_link_account_time"];
    } else if (status == LinphoneAccountCreatorAccountNotLinked) {
        [LinphoneManager.instance lpConfigSetInt:[NSDate new].timeIntervalSince1970 forKey:@"must_link_account_time"];
    } else {
        [thiz showErrorPopup:resp];
    }
}

#pragma mark - UITextFieldDelegate Functions

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    UIAssistantTextField *atf = (UIAssistantTextField *)textField;
    [atf textFieldDidBeginEditing:atf];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    UIAssistantTextField *atf = (UIAssistantTextField *)textField;
    [atf textFieldDidEndEditing:atf];
    [self shouldEnableNextButton];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    UIAssistantTextField *atf = (UIAssistantTextField *)textField;
    [textField resignFirstResponder];
    if (textField.returnKeyType == UIReturnKeyNext) {
        [atf.nextFieldResponder becomeFirstResponder];
    } else if (textField.returnKeyType == UIReturnKeyDone) {
//        [[self findButton:ViewElement_NextButton] sendActionsForControlEvents:UIControlEventTouchUpInside];
    }
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
        UIAssistantTextField *atf = (UIAssistantTextField *)textField;
        BOOL replace = YES;
        // if we are hitting backspace on secure entry, this will clear all text
        if ([string isEqual:@""] && textField.isSecureTextEntry) {
            range = NSMakeRange(0, atf.text.length);
        }
        [atf textField:atf shouldChangeCharactersInRange:range replacementString:string];
    
        
        if (textField == _createUsername) {
            [self refreshYourUsername];
        }
        [self shouldEnableNextButton];
        
        return replace;
}

#pragma mark - Action Functions

- (IBAction)onLoginClick:(id)sender {
    
    _waitView.hidden = NO;
    [self configureProxyConfig];
}

- (void)refreshYourUsername {

    
    const char* uri = NULL;
    if (!_createUsername.superview.hidden && ![_createUsername.text isEqualToString:@""]) {
        uri = linphone_account_creator_get_username(account_creator);
    } else
    if (uri) {
        _accountLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Your SIP address will be sip:%s@sip.linphone.org", nil), uri];
    } else if (!_createUsername.superview.hidden) {
        _accountLabel.text = NSLocalizedString(@"Please enter your username", nil);
    } else {
        _accountLabel.text = NSLocalizedString(@"Please enter your phone number", nil);
    }
}
@end


enum AuthorizationStatus {
  Authorized(3),
  Denied(2),
  NotDetermined(0),
  Restricted(1);

 final int value;
 const AuthorizationStatus(this.value);

}
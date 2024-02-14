final User adminUser = [SELECT Email FROM User WHERE Name='User User' LIMIT 1];
final String timezone = 'Europe/Paris';
final String locale = 'da_DK';
final String actualEmail = adminUser.Email;
final String fn = 'John';
final String ln = 'Doe';
final String alias = (fn.toLowerCase().substring(0, 1) + ln.toLowerCase()).substring(0,4) + String.valueOf(DateTime.now().getTime()).reverse().substring(0,4);
final String email = fn.toLowerCase() + '.' + ln.toLowerCase() + '@example.com';

Account a = new Account(
    Name = 'Foo Inc.'
);
INSERT a;

Contact c = new Contact();
c.FirstName = fn;
c.LastName = ln;
c.Email = email;
c.AccountId = a.Id;
INSERT c;

Profile p = [SELECT Id FROM Profile WHERE Name = 'CC Demo User' LIMIT 1];

User u = new User();
u.firstname = fn;
u.lastname = ln;
u.username = email;
u.email = actualEmail;
u.ProfileId = p.Id;
u.Contactid = c.Id;
u.alias = alias;
u.EmailEncodingKey = 'UTF-8';
u.IsActive = true;
u.LanguageLocaleKey = 'en_US';
u.LocaleSidKey = locale;
u.TimeZoneSidKey = timezone;
insert u;

// set password
final User demoUser = [SELECT Id FROM User WHERE Name='John Doe' LIMIT 1];
System.setPassword(demoUser.Id, 'Salesforce1');
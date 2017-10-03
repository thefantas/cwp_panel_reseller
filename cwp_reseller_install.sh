#!/bin/bash
clear
echo "#################################################################"
echo "#             By TheFantas® - Mod Reseller  CWP                 #"
echo "#################################################################"
echo ""

API_KEY=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 20 | head -n 1)
PASS_MYSQL=$(grep db_pass /usr/local/cwpsrv/htdocs/resources/admin/include/db_conn.php | xargs | sed 's/$db_pass = //g;s/;//g')
echo "API_KEY = $API_KEY"

touch /usr/local/cwp/.conf/api_allowed.conf
touch /usr/local/cwpsrv/htdocs/resources/client/include/3rdparty.php
touch /usr/local/cwp/.conf/api_key.conf

echo "127.0.0.1" >> /usr/local/cwp/.conf/api_allowed.conf
echo "$API_KEY" >> /usr/local/cwp/.conf/api_key.conf

# Create 3rdparty
cat > /usr/local/cwpsrv/htdocs/resources/client/include/3rdparty.php <<EOF
<li><a href="index.php?module=reseller" onClick="addURL(this)"><span class="icon16 icomoon-icon-arrow-right-3"></span>Reseller</a></li><script>
function addURL(element)
{
    \$(element).attr('href', function() {
        return this.href + '&owner='+ \$(".usernav > li > a:first").text().trim();
    });
}</script>
EOF

# MySQL Database import
mysql -u root -p$PASS_MYSQL << EOF
use root_cwp;
ALTER TABLE user ADD COLUMN owner_id int(11) NOT NULL AFTER backup;
ALTER TABLE user ADD COLUMN is_reseller int(1) NOT NULL AFTER backup;
EOF

touch /usr/local/cwpsrv/htdocs/resources/client/modules/reseller.php

# Create reseller.php
cat > /usr/local/cwpsrv/htdocs/resources/client/modules/reseller.php <<EOF
<?php
/*	By TheFantas Read */

if ( !isset( \$include_path ) )
{
    echo "invalid access";
    exit( );
}

class reseller
{
    private \$status_reseller 	= "";
    private \$version_reseller 	= "1.0";
	const HOST 					= 'https://$HOSTNAME:2031';
	const API_KEY				= '$API_KEY';

	public \$account_new 		= self::HOST."/api/?key=".self::API_KEY."&api=account_new&domain=DOMAIN_R&username=USERNAME_R&password=PASSWORD_R&package=PACKAGE_NUMBER&email=CLIENT_EMAIL&inode=10000&nofile=100&nproc=40";
	public \$account_remove 		= self::HOST."/api/?key=".self::API_KEY."&api=account_remove&username=USERNAME_R";
	public \$account_suspend 	= self::HOST."/api/?key=".self::API_KEY."&api=account_suspend&username=USERNAME_R";
	public \$account_unsuspend 	= self::HOST."/api/?key=".self::API_KEY."&api=account_unsuspend&username=USERNAME_R";
	public \$unblock_ip		 	= self::HOST."/api/?key=".self::API_KEY."&api=unblock_ip&user_ip=IP_UNBLOCK";
		
    public \$alert = "";	
	public \$owner = "";
	public \$id_username = "";

    public function __construct()
    {
		include '/usr/local/cwpsrv/htdocs/resources/admin/include/db_conn.php';
		global \$db_host, \$db_name, \$db_user, \$db_pass, \$crypt_pwd;
		@\$mysqli = new mysqli(\$db_host, \$db_user, \$db_pass, \$db_name);
		\$this->owner 			= @\$_GET['owner'];
		
		\$result 	= \$mysqli->query("SELECT id FROM user WHERE username='".\$this->owner."' LIMIT 1");
		if (\$result->num_rows > 0) {
			\$row = \$result->fetch_assoc();
			\$this->id_username 			= \$row['id'];
		}
		
		echo '<center><b>Reseller Account</b></center> <br>';
		
		\$arrContextOptions=array(
			"ssl"=>array(
				"verify_peer"=>false,
				"verify_peer_name"=>false,
			),
		); 
	
		switch (@\$_POST['api_cmd']) {
			case "account_new":
				if ((strlen(@\$_POST['domain']) > 1) && (strlen(@\$_POST['username']) == 8) && (strlen(@\$_POST['password']) > 5) && (@\$_POST['package'] > 0) && (strlen(@\$_POST['email']) > 5)) {
					\$response_cmd_api = file_get_contents(str_replace(array('DOMAIN_R', 'USERNAME_R', 'PASSWORD_R', 'PACKAGE_NUMBER', 'CLIENT_EMAIL'), array(@\$_POST['domain'], @\$_POST['username'], @\$_POST['password'], @\$_POST['package'], @\$_POST['email']), \$this->account_new), false, stream_context_create(\$arrContextOptions));
					\$this->alert 	= "alert-success";
					\$this->message 	= "<strong>Aviso!</strong> Account successfully created. <br><br>Response: ".\$response_cmd_api;
					\$this->toHtml();
					if (strpos(\$response_cmd_api, 'OK') !== FALSE)
						\$result 	= \$mysqli->query("UPDATE user SET owner_id='".\$this->id_username."' WHERE username='".@\$_POST['username']."' LIMIT 1");
				} else {
					\$this->alert 	= "alert-danger";
					\$this->message 	= "<strong>Error!</strong> Enter all fields correctly.";
					\$this->toHtml();
				}
				break;
			case "account_remove":
				if ((strlen(@\$_POST['domain']) > 1) && (strlen(@\$_POST['username']) == 8)) {
					\$response_cmd_api = file_get_contents(str_replace(array('DOMAIN_R', 'USERNAME_R'), array(@\$_POST['domain'], @\$_POST['username']), \$this->account_remove), false, stream_context_create(\$arrContextOptions));
					\$this->alert 	= "alert-success";
					\$this->message 	= "<strong>Aviso!</strong> Account successfully deleted. <br><br>Response: ".\$response_cmd_api;
					\$this->toHtml();
				} else {
					\$this->alert 	= "alert-danger";
					\$this->message 	= "<strong>Error!</strong> Account could not be deleted.";
					\$this->toHtml();
				}
				break;
			case "account_suspend":
				if ((strlen(@\$_POST['domain']) > 1) && (strlen(@\$_POST['username']) == 8)) {
					\$response_cmd_api = file_get_contents(str_replace(array('DOMAIN_R', 'USERNAME_R'), array(@\$_POST['domain'], @\$_POST['username']), \$this->account_suspend), false, stream_context_create(\$arrContextOptions));
					\$this->alert 	= "alert-success";
					\$this->message 	= "<strong>Aviso!</strong> Account successfully suspended. <br><br>Response: ".\$response_cmd_api;
					\$this->toHtml();
				} else {
					\$this->alert 	= "alert-danger";
					\$this->message 	= "<strong>Error!</strong> The account could not be suspended.".str_replace(array('DOMAIN_R', 'USERNAME_R'), array(@\$_POST['domain'], @\$_POST['username']), \$this->account_suspend);
					\$this->toHtml();
				}
				break;
			case "account_unsuspend":
				if ((strlen(@\$_POST['domain']) > 1) && (strlen(@\$_POST['username']) == 8)) {
					\$response_cmd_api = file_get_contents(str_replace(array('DOMAIN_R', 'USERNAME_R'), array(@\$_POST['domain'], @\$_POST['username']), \$this->account_unsuspend), false, stream_context_create(\$arrContextOptions));
					\$this->alert 	= "alert-success";
					\$this->message 	= "<strong>Aviso!</strong> Successfully suspended account. <br><br>Response: ".\$response_cmd_api;
					\$this->toHtml();
				} else {
					\$this->alert 	= "alert-danger";
					\$this->message 	= "<strong>Error!</strong> The account could not be suspended.";
					\$this->toHtml();
				}
				break;
			case "unblock_ip":
				if (strlen(@\$_POST['user_ip']) > 6) {
					\$response_cmd_api = file_get_contents(str_replace(array('IP_UNBLOCK'), array(@\$_POST['user_ip']), \$this->unblock_ip), false, stream_context_create(\$arrContextOptions));
					\$this->alert 	= "alert-success";
					\$this->message 	= "<strong>Aviso!</strong> Ip successfully unlocked. <br><br>Response: ".\$response_cmd_api;
					\$this->toHtml();
				} else {
					\$this->alert 	= "alert-danger";
					\$this->message 	= "<strong>Error!</strong> The ip could not be unlocked.";
					\$this->toHtml();
				}
				break;
		}
    }
	
    public function initalize()
    {
		\$this->check_is_reseller();
    }

    public function check_is_reseller()
    {		
		global \$db_host, \$db_name, \$db_user, \$db_pass, \$crypt_pwd;
		@\$mysqli = new mysqli(\$db_host, \$db_user, \$db_pass, \$db_name);
		
		/* check connection */
		if (\$mysqli->connect_error) {
			die("Error: The server can't connect to the database: Probably there isn't one.");
			exit();
		}
		
		/* change character set to utf8 */
		if (!\$mysqli->set_charset("utf8")) {
			printf("Error loading character set utf8: %s\n", \$mysqli->error);
			exit;
		}
		
		\$result 	= \$mysqli->query("SELECT is_reseller FROM user WHERE username='".\$this->owner."' LIMIT 1");
		if (\$result->num_rows > 0) {
			\$row = \$result->fetch_assoc();
			\$is_reseller 				= \$row['is_reseller'];
			
			if (\$is_reseller == 1) {
				\$package		= '<option value="0">There is no package</option>';
				
				\$result 	= \$mysqli->query("SELECT id, package_name FROM packages");
				if (\$result->num_rows > 0) {
					\$package 	= '';
					while(\$row = \$result->fetch_assoc()) {
						\$package	.= '<option value="'.\$row['id'].'">'.\$row['package_name'].'</option>';
					}
				}

				echo '<div class="panel panel-default chart gradient">
						<div class="panel-heading">
							<h4><span class="icon16 icomoon-icon-bars"></span>
								<span>Create a New Account</span>
							</h4>
						<a href="#" class="minimize" style="display: none;">Minimize</a>
						</div>
						<div class="panel-body" style="padding-bottom:0;">

					<form action="" method="post">
					<input name="api_cmd" size="0" value="account_new" type="hidden">
					<input name="ifpost" size="0" value="yes" type="hidden">
					<table><tbody><tr>
					  <td>
						<table class="summaryBlock altrowstable" width="450px" cellspacing="1" cellpadding="5" border="0" align="left">
							  <tbody><tr class="oddrowcolor">
							   <td colspan="1">Domain:</td>
							   <td colspan="1"><input name="domain" size="30" maxlength="40" class="uniform-input text" type="text"> (without www.)</td>
							  </tr>
							  
							  <tr class="oddrowcolor">
							   <td colspan="1">Username:</td>
							   <td colspan="1"><input name="username" size="10" maxlength="8" class="uniform-input text" type="text"> (8 characters)</td>
							  </tr>
							  
							  <tr class="oddrowcolor">
							   <td colspan="1">Password:</td>
							   <td colspan="1"><input name="password" value="'.substr(md5(openssl_random_pseudo_bytes(20)),-8).'" size="12" class="uniform-input text" type="text"></td>
							  </tr>
							  
							  <tr class="oddrowcolor">
								<td colspan="1">Package:</td>
								<td colspan="1">
								  <div style="width: 250px;"></span><select name="package">'.\$package.'
								  </select></div>		   
								  </td>
								</tr>
							  
							  <tr class="oddrowcolor">
								<td colspan="1">Email:</td>
								<td colspan="1"><input name="email" size="20" maxlength="50" class="uniform-input text" type="text"> (*Required)</td>
								</tr>
							  
						</tbody></table>
					</td></tr>
					<tr><td>
					<br>
					<div class="form-group">
						 <div class="col-lg-offset-3 col-lg-9">
							<button type="submit" class="btn btn-info">Create</button>
						 </div>
					</div>
					</td></tr></tbody></table>
					</form>
					<br><br>
					</div></div>';
				
				\$this->alert = "alert-info";
				\$this->message = "<strong>Welcome!</strong> Your account is Reseller.";
				\$this->toHtml();
				
				\$result 	= \$mysqli->query("SELECT * FROM user WHERE owner_id='".\$this->id_username."' AND is_reseller=0");
				if (\$result->num_rows > 0) {
					echo '<table class="table table-bordered dataTable no-footer" id="userTable" role="grid" aria-describedby="userTable_info" style="width: 100%;" width="100%" cellspacing="1" cellpadding="5" border="0" align="center">
						<thead>
						  <tr class="evenrowcolor" role="row"><th class="sorting_asc" tabindex="0" aria-controls="userTable" rowspan="1" colspan="1" style="width: 119px;" aria-label="Username: activate to sort column descending" aria-sort="ascending">Username</th><th class="sorting" tabindex="0" aria-controls="userTable" rowspan="1" colspan="1" style="width: 320px;" aria-label="Domain: activate to sort column ascending">Domain</th><th class="sorting" tabindex="0" aria-controls="userTable" rowspan="1" colspan="1" style="width: 160px;" aria-label="IP Address: activate to sort column ascending">IP Address</th><th class="sorting" tabindex="0" aria-controls="userTable" rowspan="1" colspan="1" style="width: 196px;" aria-label="Email: activate to sort column ascending">Email</th><th class="sorting" tabindex="0" aria-controls="userTable" rowspan="1" colspan="1" style="width: 208px;" aria-label="Setup Time: activate to sort column ascending">Setup Time</th><th class="sorting" tabindex="0" aria-controls="userTable" rowspan="1" colspan="1" style="width: 112px;" aria-label="Package: activate to sort column ascending">Package</th><th class="sorting" tabindex="0" aria-controls="userTable" rowspan="1" colspan="1" style="width: 195px;" aria-label="Change Password: activate to sort column ascending">Change Password</th><th class="sorting" tabindex="0" aria-controls="userTable" rowspan="1" colspan="1" style="width: 109px;" aria-label="Suspend: activate to sort column ascending">Suspend</th><th class="sorting" tabindex="0" aria-controls="userTable" rowspan="1" colspan="1" style="width: 90px;" aria-label="Delete: activate to sort column ascending">Delete</th></tr>
						</thead>
						<tbody>';
					while(\$row = \$result->fetch_assoc()) {
						\$id				= \$row['id'];
						\$username		= \$row['username'];
						\$domain			= \$row['domain'];
						\$ip_address		= \$row['ip_address'];
						\$email			= \$row['email'];
						\$setup_date		= \$row['setup_date'];
						\$package		= \$row['package'];
						\$owner_id		= \$row['owner_id'];
						echo '<tr role="row" class="odd"><td class="sorting_1">'.\$username.' <a target="_blank" title="Open UserDir http://'.\$ip_address.'/~'.\$username.'" href="http://'.\$ip_address.'/~'.\$username.'"><img src="design/img/start.png"></a></td><td>'.\$domain.' <a target="_blank" title="Open site http://'.\$domain.'" href="http://'.\$domain.'"><img src="design/img/start.png"></a></td><td>'.\$ip_address.'</td><td>'.\$email.'</td><td>'.\$setup_date.'</td><td>default</td><td><a href="index.php?module=change_account_pwd&amp;username='.\$username.'">[Change Password]</a></td><td>
							<form action="" method="post" onsubmit="return confirm(\'Are you sure you want to Suspend account: '.\$username.' ?\');">
								<input name="ifpost" size="0" value="yes" type="hidden">
								<input name="api_cmd" size="0" value="account_suspend" type="hidden">
								<input name="username" value="'.\$username.'" size="0" type="hidden">
								<input name="domain" value="'.\$domain.'" size="0" type="hidden">
								<div class="form-group">
										<button type="submit" title="Suspend User" class="btn btn-warning btn-xs">Suspend</button>
								</div>
							</form>
							<form action="" method="post" onsubmit="return confirm(\'Are you sure you want to UnSuspend account: '.\$username.' ?\');">
								<input name="ifpost" size="0" value="yes" type="hidden">
								<input name="api_cmd" size="0" value="account_unsuspend" type="hidden">
								<input name="username" value="'.\$username.'" size="0" type="hidden">
								<input name="domain" value="'.\$domain.'" size="0" type="hidden">
								<div class="form-group">
										<button type="submit" title="UnSuspend User" class="btn btn-success btn-xs">UnSuspend</button>
								</div>
							</form>
							</td><td><form action="" method="post" onsubmit="return confirm(\'Are you sure you want to delete account: '.\$username.' ?\');">
							  <input name="ifpost" size="0" value="yes" type="hidden">
							  <input name="api_cmd" size="0" value="account_remove" type="hidden">
							  <input name="username" value="'.\$username.'" size="0" type="hidden">
							  <input name="domain" value="'.\$domain.'" size="0" type="hidden">
							  <div class="form-group">
									  <button type="submit" class="btn btn-danger btn-xs">Delete</button>
							  </div>
							</form>	</td></tr>';
					}
					echo '</tbody></table>';
					
				} else {
					echo 'No reconciliation accounts.';
				}
			} else {
				\$this->alert = "alert-danger";
				\$this->message = "<strong>Error!</strong> Your account is not Reseller.";
				\$this->toHtml();
			}
			
		}
    }
	
	public function toHtml()
	{
			echo '<div class="alert '.\$this->alert.'">  
				<a class="close" data-dismiss="alert">×</a>  
				'.\$this->message.' 
			       </div>';	
	}

}

\$reseller = new reseller();
\$reseller->initalize();

?>
EOF
echo ""
echo "#################################################################"
echo "#                     finished process                          #"
echo "#################################################################"

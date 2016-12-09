# Use case Affiliate - Login

## Actors

Customer

## Main scenario

1. Customer selects to log in
2. System prompts for login (email address) and password
3. Customer enters the login and the password
4. If the login information are correct, system logs customer in
5. If the login information are incorrect, the customer is notified and the use case continues to step 2

# Code

## controller/affiliate/login.php

```php
<?php
class ControllerAffiliateLogin extends Controller {
	private $error = array();

	public function index() {
		if ($this->affiliate->isLogged()) {
			$this->response->redirect($this->url->link('affiliate/account', '', true));
		}

		$this->load->language('affiliate/login');

		$this->document->setTitle($this->language->get('heading_title'));

		$this->load->model('affiliate/affiliate');

		if (($this->request->server['REQUEST_METHOD'] == 'POST') && isset($this->request->post['email']) && isset($this->request->post['password']) && $this->validate()) {
			// Add to activity log
			if ($this->config->get('config_customer_activity')) {
				$this->load->model('affiliate/activity');

				$activity_data = array(
					'affiliate_id' => $this->affiliate->getId(),
					'name'         => $this->affiliate->getFirstName() . ' ' . $this->affiliate->getLastName()
				);

				$this->model_affiliate_activity->addActivity('login', $activity_data);
			}

			// Added strpos check to pass McAfee PCI compliance test (http://forum.opencart.com/viewtopic.php?f=10&t=12043&p=151494#p151295)
			if (isset($this->request->post['redirect']) && (strpos($this->request->post['redirect'], $this->config->get('config_url')) !== false || strpos($this->request->post['redirect'], $this->config->get('config_ssl')) !== false)) {
				$this->response->redirect(str_replace('&amp;', '&', $this->request->post['redirect']));
			} else {
				$this->response->redirect($this->url->link('affiliate/account', '', true));
			}
		}

		$data['breadcrumbs'] = array();

		$data['breadcrumbs'][] = array(
			'text' => $this->language->get('text_home'),
			'href' => $this->url->link('common/home')
		);

		$data['breadcrumbs'][] = array(
			'text' => $this->language->get('text_account'),
			'href' => $this->url->link('affiliate/account', '', true)
		);

		$data['breadcrumbs'][] = array(
			'text' => $this->language->get('text_login'),
			'href' => $this->url->link('affiliate/login', '', true)
		);

		$data['heading_title'] = $this->language->get('heading_title');

		$data['text_description'] = sprintf($this->language->get('text_description'), $this->config->get('config_name'), $this->config->get('config_name'), $this->config->get('config_affiliate_commission') . '%');
		$data['text_new_affiliate'] = $this->language->get('text_new_affiliate');
		$data['text_register_account'] = $this->language->get('text_register_account');
		$data['text_returning_affiliate'] = $this->language->get('text_returning_affiliate');
		$data['text_i_am_returning_affiliate'] = $this->language->get('text_i_am_returning_affiliate');
		$data['text_forgotten'] = $this->language->get('text_forgotten');

		$data['entry_email'] = $this->language->get('entry_email');
		$data['entry_password'] = $this->language->get('entry_password');

		$data['button_continue'] = $this->language->get('button_continue');
		$data['button_login'] = $this->language->get('button_login');

		if (isset($this->error['warning'])) {
			$data['error_warning'] = $this->error['warning'];
		} else {
			$data['error_warning'] = '';
		}

		$data['action'] = $this->url->link('affiliate/login', '', true);
		$data['register'] = $this->url->link('affiliate/register', '', true);
		$data['forgotten'] = $this->url->link('affiliate/forgotten', '', true);

		if (isset($this->request->post['redirect'])) {
			$data['redirect'] = $this->request->post['redirect'];
		} elseif (isset($this->session->data['redirect'])) {
			$data['redirect'] = $this->session->data['redirect'];

			unset($this->session->data['redirect']);
		} else {
			$data['redirect'] = '';
		}

		if (isset($this->session->data['success'])) {
			$data['success'] = $this->session->data['success'];

			unset($this->session->data['success']);
		} else {
			$data['success'] = '';
		}

		if (isset($this->request->post['email'])) {
			$data['email'] = $this->request->post['email'];
		} else {
			$data['email'] = '';
		}

		if (isset($this->request->post['password'])) {
			$data['password'] = $this->request->post['password'];
		} else {
			$data['password'] = '';
		}

		$data['column_left'] = $this->load->controller('common/column_left');
		$data['column_right'] = $this->load->controller('common/column_right');
		$data['content_top'] = $this->load->controller('common/content_top');
		$data['content_bottom'] = $this->load->controller('common/content_bottom');
		$data['footer'] = $this->load->controller('common/footer');
		$data['header'] = $this->load->controller('common/header');

		$this->response->setOutput($this->load->view('affiliate/login', $data));
	}

	protected function validate() {
		// Check how many login attempts have been made.
		$login_info = $this->model_affiliate_affiliate->getLoginAttempts($this->request->post['email']);
				
		if ($login_info && ($login_info['total'] >= $this->config->get('config_login_attempts')) && strtotime('-1 hour') < strtotime($login_info['date_modified'])) {
			$this->error['warning'] = $this->language->get('error_attempts');
		}		
		
		// Check if affiliate has been approved.
		$affiliate_info = $this->model_affiliate_affiliate->getAffiliateByEmail($this->request->post['email']);

		if ($affiliate_info && !$affiliate_info['approved']) {
			$this->error['warning'] = $this->language->get('error_approved');
		}
		
		if (!$this->error) {
			if (!$this->affiliate->login($this->request->post['email'], $this->request->post['password'])) {
				$this->error['warning'] = $this->language->get('error_login');
			
				$this->model_affiliate_affiliate->addLoginAttempt($this->request->post['email']);
			} else {
				$this->model_affiliate_affiliate->deleteLoginAttempts($this->request->post['email']);
			}
		}
		
		return !$this->error;
	}
}
```

## model/affiliate/affiliate.php

```php
<?php
class ModelAffiliateAffiliate extends Model {
	public function getAffiliateByEmail($email) {
		$query = $this->db->query("SELECT * FROM " . DB_PREFIX . "affiliate WHERE LOWER(email) = '" . $this->db->escape(utf8_strtolower($email)) . "'");

		return $query->row;
	}
	
	public function addLoginAttempt($email) {
		$query = $this->db->query("SELECT * FROM " . DB_PREFIX . "affiliate_login WHERE email = '" . $this->db->escape(utf8_strtolower((string)$email)) . "' AND ip = '" . $this->db->escape($this->request->server['REMOTE_ADDR']) . "'");

		if (!$query->num_rows) {
			$this->db->query("INSERT INTO " . DB_PREFIX . "affiliate_login SET email = '" . $this->db->escape(utf8_strtolower((string)$email)) . "', ip = '" . $this->db->escape($this->request->server['REMOTE_ADDR']) . "', total = 1, date_added = '" . $this->db->escape(date('Y-m-d H:i:s')) . "', date_modified = '" . $this->db->escape(date('Y-m-d H:i:s')) . "'");
		} else {
			$this->db->query("UPDATE " . DB_PREFIX . "affiliate_login SET total = (total + 1), date_modified = '" . $this->db->escape(date('Y-m-d H:i:s')) . "' WHERE affiliate_login_id = '" . (int)$query->row['affiliate_login_id'] . "'");
		}
	}

	public function getLoginAttempts($email) {
		$query = $this->db->query("SELECT * FROM `" . DB_PREFIX . "affiliate_login` WHERE email = '" . $this->db->escape(utf8_strtolower($email)) . "'");

		return $query->row;
	}

	public function deleteLoginAttempts($email) {
		$this->db->query("DELETE FROM `" . DB_PREFIX . "affiliate_login` WHERE email = '" . $this->db->escape(utf8_strtolower($email)) . "'");
	}	
}
```

## model/affiliate/activity.php

```php
<?php
class ModelAffiliateActivity extends Model {
	public function addActivity($key, $data) {
		if (isset($data['affiliate_id'])) {
			$affiliate_id = $data['affiliate_id'];
		} else {
			$affiliate_id = 0;
		}

		$this->db->query("INSERT INTO " . DB_PREFIX . "affiliate_activity SET `affiliate_id` = '" . (int)$affiliate_id . "', `key` = '" . $this->db->escape($key) . "', `data` = '" . $this->db->escape(json_encode($data)) . "', `ip` = '" . $this->db->escape($this->request->server['REMOTE_ADDR']) . "', `date_added` = NOW()");
	}
}
```

## view/theme/default/template/login.tpl

```php
<?php echo $header; ?>
<div class="container">
  <ul class="breadcrumb">
    <?php foreach ($breadcrumbs as $breadcrumb) { ?>
    <li><a href="<?php echo $breadcrumb['href']; ?>"><?php echo $breadcrumb['text']; ?></a></li>
    <?php } ?>
  </ul>
  <?php if ($success) { ?>
  <div class="alert alert-success"><i class="fa fa-check-circle"></i> <?php echo $success; ?></div>
  <?php } ?>
  <?php if ($error_warning) { ?>
  <div class="alert alert-danger"><i class="fa fa-exclamation-circle"></i> <?php echo $error_warning; ?></div>
  <?php } ?>
  <div class="row"><?php echo $column_left; ?>
    <?php if ($column_left && $column_right) { ?>
    <?php $class = 'col-sm-6'; ?>
    <?php } elseif ($column_left || $column_right) { ?>
    <?php $class = 'col-sm-9'; ?>
    <?php } else { ?>
    <?php $class = 'col-sm-12'; ?>
    <?php } ?>
    <div id="content" class="<?php echo $class; ?>"><?php echo $content_top; ?>
      <h1><?php echo $heading_title; ?></h1>
      <?php echo $text_description; ?>
      <div class="row">
        <div class="col-sm-6">
          <div class="well">
            <h2><?php echo $text_new_affiliate; ?></h2>
            <p><?php echo $text_register_account; ?></p>
            <a class="btn btn-primary" href="<?php echo $register; ?>"><?php echo $button_continue; ?></a></div>
        </div>
        <div class="col-sm-6">
          <div class="well">
            <h2><?php echo $text_returning_affiliate; ?></h2>
            <p><strong><?php echo $text_i_am_returning_affiliate; ?></strong></p>
            <form action="<?php echo $action; ?>" method="post" enctype="multipart/form-data">
              <div class="form-group">
                <label class="control-label" for="input-email"><?php echo $entry_email; ?></label>
                <input type="text" name="email" value="<?php echo $email; ?>" placeholder="<?php echo $entry_email; ?>" id="input-email" class="form-control" />
              </div>
              <div class="form-group">
                <label class="control-label" for="input-password"><?php echo $entry_password; ?></label>
                <input type="password" name="password" value="<?php echo $password; ?>" placeholder="<?php echo $entry_password; ?>" id="input-password" class="form-control" />
                <a href="<?php echo $forgotten; ?>"><?php echo $text_forgotten; ?></a> </div>
              <input type="submit" value="<?php echo $button_login; ?>" class="btn btn-primary" />
              <?php if ($redirect) { ?>
              <input type="hidden" name="redirect" value="<?php echo $redirect; ?>" />
              <?php } ?>
            </form>
          </div>
        </div>
      </div>
      <?php echo $content_bottom; ?></div>
    <?php echo $column_right; ?></div>
</div>
<?php echo $footer; ?>
```



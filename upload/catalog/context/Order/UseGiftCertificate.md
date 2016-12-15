# Use case Use Gift Certificate

## Actors

Customer

## Main scenario

1. Customer selects to use a gift certificate
2. System prompts for the gift certificate
3. Customer enters the gift certificate
4. System applies the gift certificate to the order

## Triggers

The use case is triggered when the "showing cart" extension point is reached

# Code

## controller/extension/total/voucher.php

```php
<?php
class ControllerExtensionTotalVoucher extends Controller {
	public function index() {
		if ($this->config->get('voucher_status')) {
			$this->load->language('extension/total/voucher');

			$data['heading_title'] = $this->language->get('heading_title');

			$data['text_loading'] = $this->language->get('text_loading');

			$data['entry_voucher'] = $this->language->get('entry_voucher');

			$data['button_voucher'] = $this->language->get('button_voucher');

			if (isset($this->session->data['voucher'])) {
				$data['voucher'] = $this->session->data['voucher'];
			} else {
				$data['voucher'] = '';
			}

			return $this->load->view('extension/total/voucher', $data);
		}
	}

	public function voucher() {
		$this->load->language('extension/total/voucher');

		$json = array();

		$this->load->model('extension/total/voucher');

		if (isset($this->request->post['voucher'])) {
			$voucher = $this->request->post['voucher'];
		} else {
			$voucher = '';
		}

		$voucher_info = $this->model_extension_total_voucher->getVoucher($voucher);

		if (empty($this->request->post['voucher'])) {
			$json['error'] = $this->language->get('error_empty');
		} elseif ($voucher_info) {
			$this->session->data['voucher'] = $this->request->post['voucher'];

			$this->session->data['success'] = $this->language->get('text_success');

			$json['redirect'] = $this->url->link('checkout/cart');
		} else {
			$json['error'] = $this->language->get('error_voucher');
		}

		$this->response->addHeader('Content-Type: application/json');
		$this->response->setOutput(json_encode($json));
	}

	public function send($route, $output, $order_id, $order_status_id) {
		$this->load->model('checkout/order');

		$order_info = $this->model_checkout_order->getOrder($order_id);

		// If order status in the complete range create any vouchers that where in the order need to be made available.
		if (in_array($order_info['order_status_id'], $this->config->get('config_complete_status'))) {
			$voucher_query = $this->db->query("SELECT *, vtd.name AS theme FROM `" . DB_PREFIX . "voucher` v LEFT JOIN " . DB_PREFIX . "voucher_theme vt ON (v.voucher_theme_id = vt.voucher_theme_id) LEFT JOIN " . DB_PREFIX . "voucher_theme_description vtd ON (vt.voucher_theme_id = vtd.voucher_theme_id) WHERE v.order_id = '" . (int)$order_info['order_id'] . "' AND vtd.language_id = '" . (int)$order_info['language_id'] . "'");

			if ($voucher_query->num_rows) {
				// Send out any gift voucher mails
				$language = new Language($order_info['language_code']);
				$language->load($order_info['language_code']);
				$language->load('mail/voucher');

				foreach ($voucher_query->rows as $voucher) {
					// HTML Mail
					$data = array();

					$data['title'] = sprintf($language->get('text_subject'), $voucher['from_name']);

					$data['text_greeting'] = sprintf($language->get('text_greeting'), $this->currency->format($voucher['amount'], $order_info['currency_code'], $order_info['currency_value']));
					$data['text_from'] = sprintf($language->get('text_from'), $voucher['from_name']);
					$data['text_message'] = $language->get('text_message');
					$data['text_redeem'] = sprintf($language->get('text_redeem'), $voucher['code']);
					$data['text_footer'] = $language->get('text_footer');

					if (is_file(DIR_IMAGE . $voucher['image'])) {
						$data['image'] = $this->config->get('config_url') . 'image/' . $voucher['image'];
					} else {
						$data['image'] = '';
					}

					$data['store_name'] = $order_info['store_name'];
					$data['store_url'] = $order_info['store_url'];
					$data['message'] = nl2br($voucher['message']);

					$mail = new Mail();
					$mail->protocol = $this->config->get('config_mail_protocol');
					$mail->parameter = $this->config->get('config_mail_parameter');
					$mail->smtp_hostname = $this->config->get('config_mail_smtp_hostname');
					$mail->smtp_username = $this->config->get('config_mail_smtp_username');
					$mail->smtp_password = html_entity_decode($this->config->get('config_mail_smtp_password'), ENT_QUOTES, 'UTF-8');
					$mail->smtp_port = $this->config->get('config_mail_smtp_port');
					$mail->smtp_timeout = $this->config->get('config_mail_smtp_timeout');

					$mail->setTo($voucher['to_email']);
					$mail->setFrom($this->config->get('config_email'));
					$mail->setSender(html_entity_decode($order_info['store_name'], ENT_QUOTES, 'UTF-8'));
					$mail->setSubject(html_entity_decode(sprintf($language->get('text_subject'), $voucher['from_name']), ENT_QUOTES, 'UTF-8'));
					$mail->setHtml($this->load->view('mail/voucher', $data));
					$mail->send();
				}
			}
		}
	}
}
```

## model/extension/total/voucher.php

```php
<?php
class ModelExtensionTotalVoucher extends Model {

	public function getVoucher($code) {
		$status = true;

		$voucher_query = $this->db->query("SELECT *, vtd.name AS theme FROM " . DB_PREFIX . "voucher v LEFT JOIN " . DB_PREFIX . "voucher_theme vt ON (v.voucher_theme_id = vt.voucher_theme_id) LEFT JOIN " . DB_PREFIX . "voucher_theme_description vtd ON (vt.voucher_theme_id = vtd.voucher_theme_id) WHERE v.code = '" . $this->db->escape($code) . "' AND vtd.language_id = '" . (int)$this->config->get('config_language_id') . "' AND v.status = '1'");

		if ($voucher_query->num_rows) {
			if ($voucher_query->row['order_id']) {
				$implode = array();

				foreach ($this->config->get('config_complete_status') as $order_status_id) {
					$implode[] = "'" . (int)$order_status_id . "'";
				}

				$order_query = $this->db->query("SELECT order_id FROM `" . DB_PREFIX . "order` WHERE order_id = '" . (int)$voucher_query->row['order_id'] . "' AND order_status_id IN(" . implode(",", $implode) . ")");

				if (!$order_query->num_rows) {
					$status = false;
				}

				$order_voucher_query = $this->db->query("SELECT order_voucher_id FROM `" . DB_PREFIX . "order_voucher` WHERE order_id = '" . (int)$voucher_query->row['order_id'] . "' AND voucher_id = '" . (int)$voucher_query->row['voucher_id'] . "'");

				if (!$order_voucher_query->num_rows) {
					$status = false;
				}
			}

			$voucher_history_query = $this->db->query("SELECT SUM(amount) AS total FROM `" . DB_PREFIX . "voucher_history` vh WHERE vh.voucher_id = '" . (int)$voucher_query->row['voucher_id'] . "' GROUP BY vh.voucher_id");

			if ($voucher_history_query->num_rows) {
				$amount = $voucher_query->row['amount'] + $voucher_history_query->row['total'];
			} else {
				$amount = $voucher_query->row['amount'];
			}

			if ($amount <= 0) {
				$status = false;
			}
		} else {
			$status = false;
		}

		if ($status) {
			return array(
				'voucher_id'       => $voucher_query->row['voucher_id'],
				'code'             => $voucher_query->row['code'],
				'from_name'        => $voucher_query->row['from_name'],
				'from_email'       => $voucher_query->row['from_email'],
				'to_name'          => $voucher_query->row['to_name'],
				'to_email'         => $voucher_query->row['to_email'],
				'voucher_theme_id' => $voucher_query->row['voucher_theme_id'],
				'theme'            => $voucher_query->row['theme'],
				'message'          => $voucher_query->row['message'],
				'image'            => $voucher_query->row['image'],
				'amount'           => $amount,
				'status'           => $voucher_query->row['status'],
				'date_added'       => $voucher_query->row['date_added']
			);
		}
	}
}
```

## model/checkout/order.php

```php
<?php
class ModelCheckoutOrder extends Model {

	public function getOrder($order_id) {
		$order_query = $this->db->query("SELECT *, (SELECT os.name FROM `" . DB_PREFIX . "order_status` os WHERE os.order_status_id = o.order_status_id AND os.language_id = o.language_id) AS order_status FROM `" . DB_PREFIX . "order` o WHERE o.order_id = '" . (int)$order_id . "'");

		if ($order_query->num_rows) {
			$country_query = $this->db->query("SELECT * FROM `" . DB_PREFIX . "country` WHERE country_id = '" . (int)$order_query->row['payment_country_id'] . "'");

			if ($country_query->num_rows) {
				$payment_iso_code_2 = $country_query->row['iso_code_2'];
				$payment_iso_code_3 = $country_query->row['iso_code_3'];
			} else {
				$payment_iso_code_2 = '';
				$payment_iso_code_3 = '';
			}

			$zone_query = $this->db->query("SELECT * FROM `" . DB_PREFIX . "zone` WHERE zone_id = '" . (int)$order_query->row['payment_zone_id'] . "'");

			if ($zone_query->num_rows) {
				$payment_zone_code = $zone_query->row['code'];
			} else {
				$payment_zone_code = '';
			}

			$country_query = $this->db->query("SELECT * FROM `" . DB_PREFIX . "country` WHERE country_id = '" . (int)$order_query->row['shipping_country_id'] . "'");

			if ($country_query->num_rows) {
				$shipping_iso_code_2 = $country_query->row['iso_code_2'];
				$shipping_iso_code_3 = $country_query->row['iso_code_3'];
			} else {
				$shipping_iso_code_2 = '';
				$shipping_iso_code_3 = '';
			}

			$zone_query = $this->db->query("SELECT * FROM `" . DB_PREFIX . "zone` WHERE zone_id = '" . (int)$order_query->row['shipping_zone_id'] . "'");

			if ($zone_query->num_rows) {
				$shipping_zone_code = $zone_query->row['code'];
			} else {
				$shipping_zone_code = '';
			}

			$this->load->model('localisation/language');

			$language_info = $this->model_localisation_language->getLanguage($order_query->row['language_id']);

			if ($language_info) {
				$language_code = $language_info['code'];
			} else {
				$language_code = $this->config->get('config_language');
			}

			return array(
				'order_id'                => $order_query->row['order_id'],
				'invoice_no'              => $order_query->row['invoice_no'],
				'invoice_prefix'          => $order_query->row['invoice_prefix'],
				'store_id'                => $order_query->row['store_id'],
				'store_name'              => $order_query->row['store_name'],
				'store_url'               => $order_query->row['store_url'],
				'customer_id'             => $order_query->row['customer_id'],
				'firstname'               => $order_query->row['firstname'],
				'lastname'                => $order_query->row['lastname'],
				'email'                   => $order_query->row['email'],
				'telephone'               => $order_query->row['telephone'],
				'fax'                     => $order_query->row['fax'],
				'custom_field'            => json_decode($order_query->row['custom_field'], true),
				'payment_firstname'       => $order_query->row['payment_firstname'],
				'payment_lastname'        => $order_query->row['payment_lastname'],
				'payment_company'         => $order_query->row['payment_company'],
				'payment_address_1'       => $order_query->row['payment_address_1'],
				'payment_address_2'       => $order_query->row['payment_address_2'],
				'payment_postcode'        => $order_query->row['payment_postcode'],
				'payment_city'            => $order_query->row['payment_city'],
				'payment_zone_id'         => $order_query->row['payment_zone_id'],
				'payment_zone'            => $order_query->row['payment_zone'],
				'payment_zone_code'       => $payment_zone_code,
				'payment_country_id'      => $order_query->row['payment_country_id'],
				'payment_country'         => $order_query->row['payment_country'],
				'payment_iso_code_2'      => $payment_iso_code_2,
				'payment_iso_code_3'      => $payment_iso_code_3,
				'payment_address_format'  => $order_query->row['payment_address_format'],
				'payment_custom_field'    => json_decode($order_query->row['payment_custom_field'], true),
				'payment_method'          => $order_query->row['payment_method'],
				'payment_code'            => $order_query->row['payment_code'],
				'shipping_firstname'      => $order_query->row['shipping_firstname'],
				'shipping_lastname'       => $order_query->row['shipping_lastname'],
				'shipping_company'        => $order_query->row['shipping_company'],
				'shipping_address_1'      => $order_query->row['shipping_address_1'],
				'shipping_address_2'      => $order_query->row['shipping_address_2'],
				'shipping_postcode'       => $order_query->row['shipping_postcode'],
				'shipping_city'           => $order_query->row['shipping_city'],
				'shipping_zone_id'        => $order_query->row['shipping_zone_id'],
				'shipping_zone'           => $order_query->row['shipping_zone'],
				'shipping_zone_code'      => $shipping_zone_code,
				'shipping_country_id'     => $order_query->row['shipping_country_id'],
				'shipping_country'        => $order_query->row['shipping_country'],
				'shipping_iso_code_2'     => $shipping_iso_code_2,
				'shipping_iso_code_3'     => $shipping_iso_code_3,
				'shipping_address_format' => $order_query->row['shipping_address_format'],
				'shipping_custom_field'   => json_decode($order_query->row['shipping_custom_field'], true),
				'shipping_method'         => $order_query->row['shipping_method'],
				'shipping_code'           => $order_query->row['shipping_code'],
				'comment'                 => $order_query->row['comment'],
				'total'                   => $order_query->row['total'],
				'order_status_id'         => $order_query->row['order_status_id'],
				'order_status'            => $order_query->row['order_status'],
				'affiliate_id'            => $order_query->row['affiliate_id'],
				'commission'              => $order_query->row['commission'],
				'language_id'             => $order_query->row['language_id'],
				'language_code'           => $language_code,
				'currency_id'             => $order_query->row['currency_id'],
				'currency_code'           => $order_query->row['currency_code'],
				'currency_value'          => $order_query->row['currency_value'],
				'ip'                      => $order_query->row['ip'],
				'forwarded_ip'            => $order_query->row['forwarded_ip'],
				'user_agent'              => $order_query->row['user_agent'],
				'accept_language'         => $order_query->row['accept_language'],
				'date_added'              => $order_query->row['date_added'],
				'date_modified'           => $order_query->row['date_modified']
			);
		} else {
			return false;
		}
	}
}
```

## view/theme/default/template/extension/total/voucher.tpl

```tpl
<div class="panel panel-default">
  <div class="panel-heading">
    <h4 class="panel-title"><a href="#collapse-voucher" data-toggle="collapse" data-parent="#accordion" class="accordion-toggle"><?php echo $heading_title; ?> <i class="fa fa-caret-down"></i></a></h4>
  </div>
  <div id="collapse-voucher" class="panel-collapse collapse">
    <div class="panel-body">
      <label class="col-sm-2 control-label" for="input-voucher"><?php echo $entry_voucher; ?></label>
      <div class="input-group">
        <input type="text" name="voucher" value="<?php echo $voucher; ?>" placeholder="<?php echo $entry_voucher; ?>" id="input-voucher" class="form-control" />
        <span class="input-group-btn">
        <input type="submit" value="<?php echo $button_voucher; ?>" id="button-voucher" data-loading-text="<?php echo $text_loading; ?>"  class="btn btn-primary" />
        </span> </div>
      <script type="text/javascript"><!--
$('#button-voucher').on('click', function() {
  $.ajax({
    url: 'index.php?route=extension/total/voucher/voucher',
    type: 'post',
    data: 'voucher=' + encodeURIComponent($('input[name=\'voucher\']').val()),
    dataType: 'json',
    beforeSend: function() {
      $('#button-voucher').button('loading');
    },
    complete: function() {
      $('#button-voucher').button('reset');
    },
    success: function(json) {
      $('.alert').remove();

      if (json['error']) {
        $('.breadcrumb').after('<div class="alert alert-danger"><i class="fa fa-exclamation-circle"></i> ' + json['error'] + '<button type="button" class="close" data-dismiss="alert">&times;</button></div>');

        $('html, body').animate({ scrollTop: 0 }, 'slow');
      }

      if (json['redirect']) {
        location = json['redirect'];
      }
    }
  });
});
//--></script>
    </div>
  </div>
</div>

```

## view/theme/default/template/mail/voucher.tpl

```php
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/1999/REC-html401-19991224/strict.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<title><?php echo $title; ?></title>
</head>
<body style="font-family: Arial, Helvetica, sans-serif; font-size: 12px; color: #000000;">
<div style="width: 680px;">
  <div style="float: right; margin-left: 20px;"><a href="<?php echo $store_url; ?>" title="<?php echo $store_name; ?>"><img src="<?php echo $image; ?>" alt="<?php echo $store_name; ?>" style="margin-bottom: 20px; border: none;" /></a></div>
  <div>
    <p style="margin-top: 0px; margin-bottom: 20px;"><?php echo $text_greeting; ?></p>
    <p style="margin-top: 0px; margin-bottom: 20px;"><?php echo $text_from; ?></p>
    <?php if ($message) { ?>
    <p style="margin-top: 0px; margin-bottom: 20px;"><?php echo $text_message; ?></p>
    <p style="margin-top: 0px; margin-bottom: 20px;"><?php echo $message; ?></p>
    <?php } ?>
    <p style="margin-top: 0px; margin-bottom: 20px;"><?php echo $text_redeem; ?></p>
    <p style="margin-top: 0px; margin-bottom: 20px;"><a href="<?php echo $store_url; ?>" title="<?php echo $store_name; ?>"><?php echo $store_url; ?></a></p>
    <p style="margin-top: 0px; margin-bottom: 20px;"><?php echo $text_footer; ?></p>
  </div>
</div>
</body>
</html>
```






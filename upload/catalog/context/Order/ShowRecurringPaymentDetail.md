# Use case Show Recurring Payment Detail

## Actors

Customer

## Main scenario

1. Customer requests to show detail of a recurring payment
2. System displays the recurring payment detail

# Code

## controller/account/recurring.php

```php
<?php
class ControllerAccountRecurring extends Controller {

	public function info() {
		$this->load->language('account/recurring');

		if (isset($this->request->get['order_recurring_id'])) {
			$order_recurring_id = $this->request->get['order_recurring_id'];
		} else {
			$order_recurring_id = 0;
		}

		if (!$this->customer->isLogged()) {
			$this->session->data['redirect'] = $this->url->link('account/recurring/info', 'order_recurring_id=' . $order_recurring_id, true);

			$this->response->redirect($this->url->link('account/login', '', true));
		}

		$this->load->model('account/recurring');

		$recurring_info = $this->model_account_recurring->getOrderRecurring($order_recurring_id);

		if ($recurring_info) {
			$this->document->setTitle($this->language->get('text_recurring'));

			$url = '';

			if (isset($this->request->get['page'])) {
				$url .= '&page=' . $this->request->get['page'];
			}

			$data['breadcrumbs'] = array();

			$data['breadcrumbs'][] = array(
				'text' => $this->language->get('text_home'),
				'href' => $this->url->link('common/home'),
			);

			$data['breadcrumbs'][] = array(
				'text' => $this->language->get('text_account'),
				'href' => $this->url->link('account/account', '', true),
			);

			$data['breadcrumbs'][] = array(
				'text' => $this->language->get('heading_title'),
				'href' => $this->url->link('account/recurring', $url, true),
			);

			$data['breadcrumbs'][] = array(
				'text' => $this->language->get('text_recurring'),
				'href' => $this->url->link('account/recurring/info', 'order_recurring_id=' . $this->request->get['order_recurring_id'] . $url, true),
			);

			$data['heading_title'] = $this->language->get('text_recurring');

			$data['text_recurring_detail'] = $this->language->get('text_recurring_detail');
			$data['text_order_recurring_id'] = $this->language->get('text_order_recurring_id');
			$data['text_date_added'] = $this->language->get('text_date_added');
			$data['text_status'] = $this->language->get('text_status');
			$data['text_payment_method'] = $this->language->get('text_payment_method');
			$data['text_order_id'] = $this->language->get('text_order_id');
			$data['text_product'] = $this->language->get('text_product');
			$data['text_quantity'] = $this->language->get('text_quantity');
			$data['text_description'] = $this->language->get('text_description');
			$data['text_reference'] = $this->language->get('text_reference');
			$data['text_transaction'] = $this->language->get('text_transaction');
			$data['text_no_results'] = $this->language->get('text_no_results');

			$data['column_date_added'] = $this->language->get('column_date_added');
			$data['column_type'] = $this->language->get('column_type');
			$data['column_amount'] = $this->language->get('column_amount');

			$data['order_recurring_id'] = $this->request->get['order_recurring_id'];
			$data['date_added'] = date($this->language->get('date_format_short'), strtotime($recurring_info['date_added']));

			if ($recurring_info['status']) {
				$data['status'] = $this->language->get('text_status_' . $recurring_info['status']);
			} else {
				$data['status'] = '';
			}

			$data['payment_method'] = $recurring_info['payment_method'];

			$data['order_id'] = $recurring_info['order_id'];
			$data['product_name'] = $recurring_info['product_name'];
			$data['product_quantity'] = $recurring_info['product_quantity'];
			$data['recurring_description'] = $recurring_info['recurring_description'];
			$data['reference'] = $recurring_info['reference'];

			// Transactions
			$data['transactions'] = array();

			$results = $this->model_account_recurring->getOrderRecurringTransactions($this->request->get['order_recurring_id']);

			foreach ($results as $result) {
				$data['transactions'][] = array(
					'date_added' => date($this->language->get('date_format_short'), strtotime($result['date_added'])),
					'type'       => $result['type'],
					'amount'     => $this->currency->format($result['amount'], $recurring_info['currency_code'])
				);
			}

			$data['order'] = $this->url->link('account/order/info', 'order_id=' . $recurring_info['order_id'], true);
			$data['product'] = $this->url->link('product/product', 'product_id=' . $recurring_info['product_id'], true);

			$data['recurring'] = $this->load->controller('extension/recurring/' . $recurring_info['payment_code']);

			$data['column_left'] = $this->load->controller('common/column_left');
			$data['column_right'] = $this->load->controller('common/column_right');
			$data['content_top'] = $this->load->controller('common/content_top');
			$data['content_bottom'] = $this->load->controller('common/content_bottom');
			$data['footer'] = $this->load->controller('common/footer');
			$data['header'] = $this->load->controller('common/header');

			$this->response->setOutput($this->load->view('account/recurring_info', $data));
		} else {
			$this->document->setTitle($this->language->get('text_recurring'));

			$data['heading_title'] = $this->language->get('text_recurring');

			$data['text_error'] = $this->language->get('text_error');

			$data['button_continue'] = $this->language->get('button_continue');

			$data['breadcrumbs'] = array();

			$data['breadcrumbs'][] = array(
				'text' => $this->language->get('text_home'),
				'href' => $this->url->link('common/home')
			);

			$data['breadcrumbs'][] = array(
				'text' => $this->language->get('text_account'),
				'href' => $this->url->link('account/account', '', true)
			);

			$data['breadcrumbs'][] = array(
				'text' => $this->language->get('heading_title'),
				'href' => $this->url->link('account/recurring', '', true)
			);

			$data['breadcrumbs'][] = array(
				'text' => $this->language->get('text_recurring'),
				'href' => $this->url->link('account/recurring/info', 'order_recurring_id=' . $order_recurring_id, true)
			);

			$data['continue'] = $this->url->link('account/recurring', '', true);

			$data['column_left'] = $this->load->controller('common/column_left');
			$data['column_right'] = $this->load->controller('common/column_right');
			$data['content_top'] = $this->load->controller('common/content_top');
			$data['content_bottom'] = $this->load->controller('common/content_bottom');
			$data['footer'] = $this->load->controller('common/footer');
			$data['header'] = $this->load->controller('common/header');

			$this->response->setOutput($this->load->view('error/not_found', $data));
		}
	}
}
```

## model/account/recurring.php

```php
<?php
class ModelAccountRecurring extends Model {
	public function getOrderRecurring($order_recurring_id) {
		$query = $this->db->query("SELECT `or`.*,`o`.`payment_method`,`o`.`payment_code`,`o`.`currency_code` FROM `" . DB_PREFIX . "order_recurring` `or` LEFT JOIN `" . DB_PREFIX . "order` `o` ON `or`.`order_id` = `o`.`order_id` WHERE `or`.`order_recurring_id` = '" . (int)$order_recurring_id . "' AND `o`.`customer_id` = '" . (int)$this->customer->getId() . "'");

		return $query->row;
	}
	public function getOrderRecurringTransactions($order_recurring_id) {
		$query = $this->db->query("SELECT * FROM `" . DB_PREFIX . "order_recurring_transaction` WHERE `order_recurring_id` = '" . (int)$order_recurring_id . "'");

		return $query->rows;
	}

}
```

## view/theme/default/template/account/recurring_info.tpl

```php
<?php echo $header; ?>
<div class="container">
  <ul class="breadcrumb">
    <?php foreach ($breadcrumbs as $breadcrumb) { ?>
    <li><a href="<?php echo $breadcrumb['href']; ?>"><?php echo $breadcrumb['text']; ?></a></li>
    <?php } ?>
  </ul>
  <div class="row"><?php echo $column_left; ?>
    <?php if ($column_left && $column_right) { ?>
    <?php $class = 'col-sm-6'; ?>
    <?php } elseif ($column_left || $column_right) { ?>
    <?php $class = 'col-sm-9'; ?>
    <?php } else { ?>
    <?php $class = 'col-sm-12'; ?>
    <?php } ?>
    <div id="content" class="<?php echo $class; ?>"><?php echo $content_top; ?>
      <h2><?php echo $heading_title; ?></h2>
      <div class="table-responsive">
        <table class="table table-bordered table-hover">
          <thead>
            <tr>
              <td class="text-left" colspan="2"><?php echo $text_recurring_detail; ?></td>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td class="text-left" style="width: 50%;"><b><?php echo $text_order_recurring_id; ?></b> #<?php echo $order_recurring_id; ?><br />
                <b><?php echo $text_date_added; ?></b> <?php echo $date_added; ?><br />
                <b><?php echo $text_status; ?></b> <?php echo $status; ?><br />
                <b><?php echo $text_payment_method; ?></b> <?php echo $payment_method; ?></td>
              <td class="text-left" style="width: 50%;"><b><?php echo $text_order_id; ?></b> <a href="<?php echo $order; ?>">#<?php echo $order_id; ?></a><br />
                <b><?php echo $text_product; ?></b> <a href="<?php echo $product; ?>"><?php echo $product_name; ?></a><br />
                <b><?php echo $text_quantity; ?></b> <?php echo $product_quantity; ?></td>
            </tr>
          </tbody>
        </table>
        <table class="table table-bordered table-hover">
          <thead>
            <tr>
              <td class="text-left"><?php echo $text_description; ?></td>
              <td class="text-left"><?php echo $text_reference; ?></td>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td class="text-left" style="width: 50%;"><?php echo $recurring_description; ?></td>
              <td class="text-left" style="width: 50%;"><?php echo $reference; ?></td>
            </tr>
          </tbody>
        </table>
      </div>
      <h3><?php echo $text_transaction; ?></h3>
      <div class="table-responsive">
        <table class="table table-bordered table-hover">
          <thead>
            <tr>
              <td class="text-left"><?php echo $column_date_added; ?></td>
              <td class="text-left"><?php echo $column_type; ?></td>
              <td class="text-right"><?php echo $column_amount; ?></td>
            </tr>
          </thead>
          <tbody>
            <?php if ($transactions) { ?>
            <?php foreach ($transactions as $transaction) { ?>
            <tr>
              <td class="text-left"><?php echo $transaction['date_added']; ?></td>
              <td class="text-left"><?php echo $transaction['type']; ?></td>
              <td class="text-right"><?php echo $transaction['amount']; ?></td>
            </tr>
            <?php } ?>
            <?php } else { ?>
            <tr>
              <td colspan="3" class="text-center"><?php echo $text_no_results; ?></td>
            </tr>
            <?php } ?>
          </tbody>
        </table>
      </div>
      <?php echo $recurring; ?><?php echo $content_bottom; ?></div>
    <?php echo $column_right; ?></div>
</div>
<?php echo $footer; ?>
```


## view/theme/default/template/error/not_found.tpl

```php
<?php echo $header; ?>
<div class="container">
  <ul class="breadcrumb">
    <?php foreach ($breadcrumbs as $breadcrumb) { ?>
    <li><a href="<?php echo $breadcrumb['href']; ?>"><?php echo $breadcrumb['text']; ?></a></li>
    <?php } ?>
  </ul>
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
      <p><?php echo $text_error; ?></p>
      <div class="buttons clearfix">
        <div class="pull-right"><a href="<?php echo $continue; ?>" class="btn btn-primary"><?php echo $button_continue; ?></a></div>
      </div>
      <?php echo $content_bottom; ?></div>
    <?php echo $column_right; ?></div>
</div>
<?php echo $footer; ?>
```

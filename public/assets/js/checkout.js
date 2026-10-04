(function () {
  var EMAILJS = {
    publicKey: 'UyTns5KU22ahbrp4f',
    serviceId: 'service_qglj85l',
    templateId: 'template_hfjt2zf',
    toEmail: 'help@easyeyepuzzles.com'
  };

  var form = document.getElementById('checkout-form');
  if (!form) return;
  var btn = form.querySelector('button[type="submit"]');
  var btnLabel = btn.textContent;
  var errorBox = document.getElementById('form-error');
  var done = document.getElementById('order-done');

  function orderId() {
    var d = new Date();
    var pad = function (n) { return (n < 10 ? '0' : '') + n; };
    var rand = Math.random().toString(36).slice(2, 6).toUpperCase();
    return 'EEP-' + String(d.getFullYear()).slice(2) + pad(d.getMonth() + 1) + pad(d.getDate()) + '-' + rand;
  }

  function showError(msg) {
    errorBox.textContent = msg;
    errorBox.hidden = false;
    errorBox.focus();
  }

  form.addEventListener('submit', function (e) {
    e.preventDefault();
    errorBox.hidden = true;

    // Honeypot: real people never fill this hidden field
    if (form.elements.website && form.elements.website.value) return;

    var name = form.elements.name.value.trim();
    var email = form.elements.email.value.trim();
    var phone = form.elements.phone.value.trim();
    if (!name || !email || !phone) { showError('Please fill in your name, email and phone number.'); return; }
    if (!form.elements.email.checkValidity()) { showError('Please enter a valid email address.'); form.elements.email.focus(); return; }
    if (phone.replace(/\D/g, '').length < 6) { showError('Please enter a valid phone number.'); form.elements.phone.focus(); return; }

    if (!window.emailjs) { showError('The order form could not load. Please check your connection and try again, or email us at ' + EMAILJS.toEmail + '.'); return; }

    var d = form.dataset;
    var id = orderId();
    var message =
      'New order ' + id + '\n\n' +
      'Product: ' + d.product + '\n' +
      'Type: ' + d.kind + '\n' +
      'Price: ' + d.price + ' USD\n' +
      'Product page: ' + d.url + '\n\n' +
      'Customer name: ' + name + '\n' +
      'Customer email: ' + email + '\n' +
      'Customer phone: ' + phone + '\n';

    var params = {
      order_id: id,
      product_name: d.product,
      product_type: d.kind,
      product_price: d.price,
      product_url: d.url,
      customer_name: name,
      customer_email: email,
      customer_phone: phone,
      // common aliases so the email template can use whichever names it prefers
      name: name,
      email: email,
      phone: phone,
      from_name: name,
      reply_to: email,
      to_email: EMAILJS.toEmail,
      title: 'New order: ' + d.product + ' (' + d.price + ')',
      subject: 'New order ' + id + ': ' + d.product,
      message: message,
      time: new Date().toLocaleString()
    };

    btn.disabled = true;
    btn.textContent = 'Sending your order...';

    emailjs.send(EMAILJS.serviceId, EMAILJS.templateId, params, { publicKey: EMAILJS.publicKey })
      .then(function () {
        form.hidden = true;
        document.getElementById('done-id').textContent = id;
        document.getElementById('done-email').textContent = email;
        done.hidden = false;
        done.focus();
      }, function (err) {
        btn.disabled = false;
        btn.textContent = btnLabel;
        showError('Sorry, your order could not be sent (' + ((err && (err.text || err.status)) || 'network error') + '). Please try again, or email us at ' + EMAILJS.toEmail + '.');
      });
  });
})();

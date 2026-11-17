use uppsala::XmlError;
use std::path::Path;

mod atoms {
    rustler::atoms! {
        other_atom
    }
}

#[rustler::nif(schedule = "DirtyCpu")]
fn parse(xml: &str) -> (rustler::Atom,String) {
	use rustler::types::atom;
	match do_parse(xml) {
		Ok(doc)  => (atom::ok(), doc),
		Err(err) => (atom::error(), format!("{}",err))
	}
}

fn do_parse(xml: &str) -> Result<String,XmlError> {
	use uppsala::{parse, XmlWriteOptions};
	let doc = parse(xml)?;
	let opts = XmlWriteOptions::pretty("  ");
	Ok(doc.to_xml_with_options(&opts))
}

#[rustler::nif(schedule = "DirtyCpu")]
fn validate(xml: &str, schema: &str) -> (rustler::Atom,String) {
	
	use rustler::types::atom;
	match do_validate(xml, schema, Some(&Path::new("priv/xml_schema"))) {
		Ok(d)  => (atom::ok(),d),
		Err(e) => {
			let ret = e.iter().map(|err| err.to_string()).collect::<Vec<String>>();
			(atom::error(),ret.join("\n"))
		}
	}
}

#[rustler::nif(schedule = "DirtyCpu")]
fn validate(xml: &str, schema: &str, schema_path: Option<&Path>) -> (rustler::Atom,String) {
	
	use rustler::types::atom;
	match do_validate(xml, schema, schema_path) {
		Ok(d)  => (atom::ok(),d),
		Err(e) => {
			let ret = e.iter().map(|err| err.to_string()).collect::<Vec<String>>();
			(atom::error(),ret.join("\n"))
		}
	}
}

fn setup_validator(schema: &str, schema_path: Option<&Path>) -> Result<uppsala::XsdValidator,Vec<XmlError>> {
	use uppsala::{parse, XsdValidator};
	let schema_doc = parse(schema).map_err(|e| { vec![e]})?;
	Ok(XsdValidator::from_schema_with_base_path(&schema_doc,schema_path).map_err(|e| vec![e])?)
}

fn do_validate(xml: &str, schema: &str, schema_path: Option<&Path> ) -> Result<String,Vec<XmlError>> {
	use uppsala::parse;
	let mut out = Vec::new();
	let mut validator = setup_validator(schema, schema_path)?;
	validator.set_lenient(true);
	let doc = parse(xml).map_err(|e| vec![e])?;
	for err in validator.validate(&doc) {
		out.push(uppsala::XmlError::Validation(err));
	}
	if out.len() > 0 {
		return Err(out);
	}
	Ok(doc.to_string())
}

#[rustler::nif(schedule = "DirtyCpu")]
fn verify(xml: &str, cert: &str) -> (rustler::Atom,String) {
	use rustler::types::atom;
	match do_verify(xml, cert) {
		Ok(res) => (atom::ok(),format!("{}",res)),
		Err(e)  => (atom::error(), format!("{}",e))
	}
}

pub fn do_verify(xml: &str, cert: &str) -> Result<bool,bergshamra::Error> {
	use bergshamra::KeysManager; 
	use bergshamra::DsigContext; 
	use bergshamra::VerifyResult; 

	let key = bergshamra::keys::loader::load_pem_auto(cert.as_bytes(),None)?;
	let mut keys_manager = KeysManager::new();
	keys_manager.add_key(key);
	let mut ctx = DsigContext::new(keys_manager);
	ctx.trusted_keys_only = true;     // reject inline keys
	ctx.strict_verification = true;   // reject unexpected reference positions
	match bergshamra::verify(&ctx, xml)? {
		VerifyResult::Valid{
			signature_node: _,
			references: _,
			key_info: _
		                   }   => Ok(true),
		VerifyResult::Invalid{
			reason: _
		                     } => Ok(false)
	}
}

#[rustler::nif(schedule = "DirtyCpu")]
fn transform(xml: &str, xslt: &str) -> (rustler::Atom,String) {
	use rustler::types::atom;
	match do_transform(xml, xslt, vec![]) {
		Ok(doc) => (atom::ok(),doc),
		Err(e)  => (atom::error(), format!("{}",e))
	}
}

#[rustler::nif(schedule = "DirtyCpu")]
fn transform(xml: &str, xslt: &str, params: Vec<(String,String)>) -> (rustler::Atom,String) {

	use rustler::types::atom;
	match do_transform(xml, xslt, params) {
		Ok(doc) => (atom::ok(),doc),
		Err(e)  => (atom::error(), format!("{}",e))
	}
}

pub fn do_transform(xml: &str, xslt: &str, params: Vec<(String,String)>) -> Result<String,XmlError> {

	let xslt_doc = uppsala::parse(xslt)?;
	let mut stylesheet = uppsala::xslt::Stylesheet::compile(&xslt_doc)?;
	let mut xml_doc = uppsala::parse(xml)?;
	xml_doc.prepare_xpath();
	for (k,v) in params {
		stylesheet = stylesheet.with_param(k,v);
	}
	Ok(stylesheet.transform(&xml_doc)?)
}

#[rustler::nif(schedule = "DirtyCpu")]
fn list_ids(xml: &str) -> (rustler::Atom,Vec<String>) {
	use rustler::types::atom;
	match do_list_ids(xml) {
		Ok(doc)  => (atom::ok(), doc),
		Err(err) => (atom::error(), vec![format!("{}",err)])
	}
}

fn do_list_ids(xml: &str) -> Result<Vec<String>,XmlError> {
	use uppsala::parse;
	let doc = parse(xml)?;
	
	let mut ids = vec![];
	let entities = doc.get_elements_by_tag_name("EntityDescriptor");
	for entity in &entities {
		if let Some(entity_id) = doc.get_attribute(*entity,"entityID") {
			ids.push(entity_id.to_string());
		}
	}
	
	Ok(ids)
}

#[rustler::nif(schedule = "DirtyCpu")]
fn extract_entities(xml: &str,entity_id: &str) -> (rustler::Atom,Vec<String>) {
	use rustler::types::atom;
	match do_extract_entities(xml,entity_id) {
		Ok(doc)  => (atom::ok(), doc),
		Err(err) => (atom::error(), vec![format!("{}",err)])
	}
}

fn do_extract_entities(xml: &str, entity_id: &str) -> Result<Vec<String>,XmlError> {
	use uppsala::{parse,XPathEvaluator,XPathValue};
	let mut doc = parse(xml)?;
	doc.prepare_xpath();
	let mut eval = XPathEvaluator::new().with_max_node_visits(10000000);
	eval.add_namespace("md", "urn:oasis:names:tc:SAML:2.0:metadata");
	let root = doc.root();
	let mut out = vec![];
	if let XPathValue::NodeSet(nodes) = eval.evaluate(&doc, root, &format!("//md:EntitiesDescriptor/md:EntityDescriptor[@entityID='{}']",&entity_id))? {
		for node in nodes {
			out.push(doc.node_to_xml(node));
		}
	}
	Ok(out)
}

#[rustler::nif(schedule = "DirtyCpu")]
fn tidy(xml: &str) -> (rustler::Atom, String) {
	use rustler::types::atom;
	match do_tidy(xml) {
		Ok(doc)  => (atom::ok(), doc),
		Err(err) => (atom::error(), format!("{}",err))
	}
}

fn do_tidy(xml: &str) -> Result<String,XmlError> {
  use uppsala::{parse, XmlWriteOptions};
  let doc = parse(xml).unwrap();
  let opts = XmlWriteOptions::pretty("  ");
  let out = doc.to_xml_with_options(&opts);
  Ok(out)
}

rustler::init!("Elixir.Smee.XMLProcessor.Uppsala.Native");

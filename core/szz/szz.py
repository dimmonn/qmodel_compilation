from transformers import pipeline

classifier = pipeline(
    "zero-shot-classification",
    model="facebook/bart-large-mnli"
)

def predict_bug_probability(patch: str):
    result = classifier(
        patch,
        candidate_labels=[
            "bug introducing change",
            "safe refactoring or improvement"
        ],
        hypothesis_template="This patch is a {}."
    )

    # Score of first label
    return float(result["scores"][0])
patch = """
@@ -1,20 +1,27 @@
 ---
-- debug: msg="START cli/src_match_none.yaml"
+- debug: msg="START {{ connection.transport }}/src_match_none.yaml"
+
+# Select interface for test
+- set_fact: intname="{{ nxos_int1 }}"
 
 - name: setup
   nxos_config:
     commands:
       - no description
       - no shutdown
     parents:
-      - interface Ethernet2/5
+      - "interface {{ intname }}"
     match: none
-    provider: "{{ cli }}"
+    provider: "{{ connection }}"
 
 - name: configure device with config
   nxos_config:
-    src: basic/config.j2
-    provider: "{{ cli }}"
+    commands:
+      - description this is a test
+      - shutdown
+    parents:
+      - "interface {{ intname }}"
+    provider: "{{ connection }}"
     match: none
     defaults: yes
   register: result
@@ -27,8 +34,12 @@
 
 - name: check device with config
   nxos_config:
-    src: basic/config.j2
-    provider: "{{ cli }}"
+    commands:
+      - description this is a test
+      - shutdown
+    parents:
+      - "interface {{ intname }}"
+    provider: "{{ connection }}"
     defaults: yes
   register: result
 
@@ -39,4 +50,4 @@
       - "result.changed == false"
       - "result.updates is not defined"
 
-- debug: msg="END cli/src_match_none.yaml"
+- debug: msg="END {{ connection.transport }}/src_match_none.yaml"
"""

predict_bug_probability(patch)
print()
# common

Shared AmiInternals code belongs here.

The compatibility layer should centralize:

- Exec and DOS version detection;
- safe list traversal helpers;
- common text/number formatting;
- tool version/banner handling;
- runtime feature checks;
- compatibility-sensitive structure access.

Avoid importing newer AmigaOS assumptions into individual utilities.

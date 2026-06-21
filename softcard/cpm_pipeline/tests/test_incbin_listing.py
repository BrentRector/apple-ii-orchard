"""Drift guard: every cross-CPU INCBIN site must carry the verbatim source
listing of the block it embeds, kept in sync with the actual source file.

If this fails, an embedded Z-80/6502 block's source changed but the listing
comment in the host file was not regenerated -- run:
    python -m cpm_pipeline.inject_incbin_listing
"""
from cpm_pipeline.inject_incbin_listing import check_all


def test_incbin_listings_in_sync():
    problems = check_all()
    assert not problems, "INCBIN listing(s) out of sync:\n" + "\n".join(problems)
